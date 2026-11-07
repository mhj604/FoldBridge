import Foundation
import CoreBluetooth
import CryptoKit
import UserNotifications
import WatchKit
import Combine

enum PhoneProfile: String {
    case original, local
    var title: String { self == .local ? "FoldBridge Local" : "기존 FoldBridge" }
    var service: String { self == .local ? "C62D0200-7DE5-4C34-A432-7C838E687A40" : Wire.service }
    var tx: String { self == .local ? "C62D0201-7DE5-4C34-A432-7C838E687A40" : Wire.tx }
    var rx: String { self == .local ? "C62D0202-7DE5-4C34-A432-7C838E687A40" : Wire.rx }
}

struct PhoneCandidate: Identifiable {
    let peripheral: CBPeripheral
    var id: UUID { peripheral.identifier }
    var name: String { peripheral.name ?? AppLanguage.shared.text("Android 휴대폰") }
}
struct WatchAlert {
    let id: String, app: String, title: String, body: String
    let received: Date
    let appID: String?
    let iconKey: String?
}

final class WatchLink: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = WatchLink()
    @Published var status = "휴대폰 연결을 시작하세요"
    @Published var candidates: [PhoneCandidate] = []
    @Published var code = ""
    @Published var connected = false
    @Published var lastError = ""
    @Published var notificationAllowed = false
    @Published var backgroundNotice = ""
    @Published private(set) var vehicleActions: [VehicleAction] = []
    @Published private(set) var vehicleState = "loading"
    @Published private(set) var vehicleResult = ""
    @Published private(set) var vehicleBusy = false
    private var vehicleRevision = ""
    private var vehicleRequestID: String?
    @Published private(set) var receivedCount = UserDefaults.standard.integer(forKey:"diagnosticReceived")
    @Published private(set) var scheduledCount = UserDefaults.standard.integer(forKey:"diagnosticScheduled")
    @Published private(set) var profile: PhoneProfile = {
        let defaults = UserDefaults.standard
        if let saved = defaults.string(forKey:"phoneProfile"), let profile = PhoneProfile(rawValue:saved) { return profile }
        return defaults.string(forKey:"phoneID") == nil ? .local:.original
    }()
    private var peerKey: String { profile == .local ? "peer.local" : "peer" }
    private var phoneIDKey: String { profile == .local ? "phoneID.local" : "phoneID" }
    private var switchingFrom: CBPeripheral?
    private var refreshAfterDisconnect = false
    private var lastManualRefresh = Date.distantPast
    private var maintenanceTimer: Timer?
    private var lastMaintenance = Date.distantPast
    private var runtimeWindowStart = Date()
    private var connectionAttemptAt = Date.distantPast
    private var lastPeerActivity = Date.distantPast
    private var foregroundSince = Date()
    private var lastWriteAt = Date.distantPast
    private var lastFailure = ""
    private var failureCounts: [String:Int] = [:]
    private var softRefreshCount = 0
    private var lastIncomingActivity = Date.distantPast
    private var pongCount = 0
    private var remoteRefreshCount = 0
    private var pendingPing: String?
    private var pingSentAt = Date.distantPast
    private var peerSupportsLiveness = false
    private var refreshCount = 0
    private var manager: CBCentralManager!
    private var peripheral: CBPeripheral?, tx: CBCharacteristic?, rx: CBCharacteristic?
    private let framer = Wire.Framer(), assembler = Wire.Assembler()
    private var outgoing: [Data] = [], writing = false
    private var writingEpoch = 0
    private var writingFrame: Data?
    private let processID = UUID().uuidString
    private var identity: P256.KeyAgreement.PrivateKey?, session: Wire.Session?
    private var ownNonce = Data(), phonePublic = Data(), phoneCommit = Data()
    private var stage = "idle", localConfirmed = false, remoteConfirmed = false
    private var active = WKApplication.shared().applicationState == .active
    private var continuousRuntime = false
    private var canProcessContinuously: Bool { active || continuousRuntime }
    private var epoch = 0, scanEpoch = 0, reconnects = 0
    private var seen: [String: String] = [:]
    private var seenOrder: [String] = []
    private var reconnectWork: DispatchWorkItem?, backgroundIdleWork: DispatchWorkItem?
    private var recoveryScanning = false
    private var autoReconnectPending = false
    private var refreshingServices = false
    private var serviceDiscoveryWork: DispatchWorkItem?
    private var serviceDiscoveryAttempts = 0
    private var serviceWaitCount = 0
    private var nextServiceDiscovery = Date.distantPast
    private var lastServiceDiscoveryError = ""
    private var nextConnectAttempt = Date.distantPast
    private var lastConnectError = ""
    private var cancellationCount = 0
    private var lastCancellation = ""
    private var lastDisconnect = ""
    private var nextRecoveryRefresh = Date.distantPast
    private var lastIncomingFrame: Data?, lastSync = Date.distantPast
    private var pendingReceipts: [(alert: WatchAlert, revision: String)] = []
    private var presentingReceipt = false
    private struct ReceiptLedger: Codable {
        let seen: [String: String]
        let order: [String]
    }
    private var backgroundTasks: [WKRefreshBackgroundTask] = []
    override private init() {
        super.init()
        do {
            identity = try WatchStore.identity()
            if let saved = try WatchStore.get("seen"), let data = try JSONSerialization.jsonObject(with:saved) as? [String:String] { seen = data }
            // The legacy inbox is decoded as receipt metadata only; message fields are ignored.
            let savedLedger = try WatchStore.get("receipts") ?? WatchStore.get("inbox")
            if let data = savedLedger, let saved = try? JSONDecoder().decode(ReceiptLedger.self,from:data) {
                seen = saved.seen; seenOrder = saved.order
            } else { seenOrder = seen.keys.sorted() }
            try WatchStore.put("receipts",JSONEncoder().encode(ReceiptLedger(seen:seen,order:seenOrder)))
            WatchStore.remove("inbox")
            WatchStore.remove("seen")
        } catch { lastError = "보안 저장소를 사용할 수 없습니다." }
        manager = CBCentralManager(delegate:self, queue:nil, options:[
            CBCentralManagerOptionShowPowerAlertKey:true,
            CBCentralManagerOptionRestoreIdentifierKey:"dev.foldbridge.watch.central"
        ])
        refreshNotificationSettings()
        updateMaintenanceTimer()
        trace("launch")
    }
    func refreshNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationAllowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                if self.notificationAllowed { self.presentNextReceipt() }
                self.writeDiagnostics()
            }
        }
    }
    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.sound]) { allowed,error in
            DispatchQueue.main.async {
                self.notificationAllowed = allowed
                if error != nil { self.lastError = "워치 알림 권한을 확인하세요." }
                if allowed { self.presentNextReceipt(); self.synchronize() }
                self.writeDiagnostics()
            }
        }
    }
    func scan() {
        guard active else { return }
        guard manager.state == .poweredOn, identity != nil else { lastError = "블루투스와 앱 권한을 확인하세요."; return }
        recoveryScanning = false
        candidates = []; lastError = ""; status = "FoldBridge 휴대폰 찾는 중"
        scanEpoch += 1
        manager.scanForPeripherals(withServices:[CBUUID(string:profile.service)], options:nil)
        let current = scanEpoch
        DispatchQueue.main.asyncAfter(deadline:.now()+20) { if current == self.scanEpoch { self.manager.stopScan(); if self.candidates.isEmpty { self.status = "휴대폰에서 연결 시작을 누르세요" } } }
    }
    func connect(_ phone: PhoneCandidate) {
        guard switchingFrom == nil else { return }
        guard peripheral?.identifier != phone.id else { return }
        let old = peripheral
        reconnectWork?.cancel(); reconnectWork = nil
        resetSession()
        if let old { cancelConnection(old,reason:"replace") }
        recoveryScanning = false
        connectionAttemptAt = Date()
        peripheral = phone.peripheral; phone.peripheral.delegate = self; manager.stopScan(); status = "휴대폰 연결 대기 중"
        if phone.peripheral.state == .connected { beginDiscovery(phone.peripheral) }
        else { manager.connect(phone.peripheral,options:connectionOptions()) }
        // A trusted peripheral's pending connect remains with Core Bluetooth while out of range.
        if (try? WatchStore.get(peerKey)) != nil {
            // Register discovery now; a delayed fallback may never run after suspension.
            startRecoveryScan();scheduleDiscoveryFallback();return
        }
        let current = epoch
        DispatchQueue.main.asyncAfter(deadline:.now()+120) { if current == self.epoch && self.active && !self.connected && Date().timeIntervalSince(self.foregroundSince) >= 120 { self.fail("연결 확인 시간이 만료됐습니다.") } }
    }
    private func scheduleDiscoveryFallback() {
        let current = epoch
        DispatchQueue.main.asyncAfter(deadline:.now()+20) {
            guard current == self.epoch, !self.connected,
                  self.peripheral?.state == .connecting else { return }
            // Preserve the OS pending connection while looking for a changed phone address.
            self.startRecoveryScan()
        }
    }
    private func connectionOptions() -> [String: Any]? {
        guard (try? WatchStore.get(peerKey)) != nil else { return nil }
        if #available(watchOS 10.0, *) {
            return [CBConnectPeripheralOptionEnableAutoReconnect: true]
        }
        return nil
    }
    func refreshConnection() {
        guard Date().timeIntervalSince(lastManualRefresh) >= 3 else { return }
        lastManualRefresh = Date()
        refreshCount += 1
        if connected, peripheral?.state == .connected {
            lastError = ""; softRefreshCount += 1
            sendSecure(["type":"refresh"])
            lastSync = .distantPast; synchronize(); writeDiagnostics()
        } else { restartSavedConnection() }
    }
    private func restartSavedConnection() {
        guard manager.state == .poweredOn else { lastError = "워치 Bluetooth를 켜 주세요.";return }
        if identity == nil { identity = try? WatchStore.identity() }
        guard UserDefaults.standard.string(forKey:phoneIDKey) != nil, (try? WatchStore.get(peerKey)) != nil else { scan();return }
        refreshCount += 1
        let old = peripheral ?? switchingFrom
        reconnectWork?.cancel();reconnectWork = nil;reconnects = 0;nextConnectAttempt = .distantPast
        manager.stopScan();recoveryScanning = false;resetSession()
        lastError = "";backgroundNotice = "";status = "연결 새로고침 중"
        if let old, old.state != .disconnected {
            switchingFrom = old;refreshAfterDisconnect = false
            cancelConnection(old,reason:"refresh")
            let current = epoch
            DispatchQueue.main.asyncAfter(deadline:.now()+3) {
                guard self.epoch == current, self.switchingFrom === old else { return }
                self.switchingFrom = nil;self.refreshAfterDisconnect = false;self.reconnect()
            }
        } else {
            switchingFrom = nil;refreshAfterDisconnect = false;reconnect()
        }
        scheduleRecoveryRefresh();writeDiagnostics()
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        trace("bluetooth.\(central.state.rawValue)")
        if central.state == .poweredOn {
            if peripheral?.state == .disconnected { autoReconnectPending = false }
            reconnect()
        }
        else { switchingFrom = nil;refreshAfterDisconnect = false;resetSession();status = "블루투스를 켜세요" }
    }
    func resumeSavedConnection() {
        if identity == nil { identity = try? WatchStore.identity() }
        scheduleRecoveryRefresh()
        reconnect()
    }
    private func scheduleRecoveryRefresh() {
        guard UserDefaults.standard.string(forKey:phoneIDKey) != nil,
              nextRecoveryRefresh <= Date() else { return }
        let preferred = Date().addingTimeInterval(30*60)
        nextRecoveryRefresh = preferred
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate:preferred,userInfo:"foldbridge.reconnect" as NSString) { error in
            if error != nil { DispatchQueue.main.async { self.nextRecoveryRefresh = .distantPast } }
        }
        // The preferred date is a request, not a boot hook or a guaranteed execution time.
    }
    private func reconnect() {
        guard switchingFrom == nil, manager.state == .poweredOn, Date() >= nextConnectAttempt else { return }
        if let existing = peripheral {
            if existing.state == .connected, stage == "idle" { beginDiscovery(existing) }
            // A disconnected cached object without an OS-owned reconnect used to
            // make every resume return early, leaving no native pending connection.
            if existing.state != .disconnected || autoReconnectPending { return }
            resetSession()
            connect(PhoneCandidate(peripheral:existing));return
        }
        guard let text = UserDefaults.standard.string(forKey:phoneIDKey), let id = UUID(uuidString:text) else { return }
        if identity == nil { identity = try? WatchStore.identity() }
        guard identity != nil, (try? WatchStore.get(peerKey)) != nil else { return }
        if let p = manager.retrievePeripherals(withIdentifiers:[id]).first {
            connect(PhoneCandidate(peripheral:p));return
        }
        startRecoveryScan()
    }
    private func startRecoveryScan() {
        guard manager.state == .poweredOn, !connected,
              peripheral?.state != .connected || stage == "waitingForService", !manager.isScanning,
              UserDefaults.standard.string(forKey:phoneIDKey) != nil,
              (try? WatchStore.get(peerKey)) != nil else { return }
        // A missing OS cache entry must not force the user to register the same phone again.
        // Discovery still authenticates the saved public key before any alert is accepted.
        recoveryScanning = true;scanEpoch += 1
        status = "등록된 휴대폰을 다시 찾는 중"
        manager.scanForPeripherals(withServices:[CBUUID(string:profile.service)],options:nil)
        // Leave this service-filtered recovery scan with Core Bluetooth while out
        // of range. A foreground-only timeout must not remove background discovery.
    }
    private func retryConnection() {
        guard reconnectWork == nil, UserDefaults.standard.string(forKey:phoneIDKey) != nil else { return }
        reconnects += 1
        let delay = min(30.0,pow(2.0,Double(min(reconnects,5))))
        nextConnectAttempt = Date().addingTimeInterval(delay)
        let work = DispatchWorkItem { [weak self] in self?.reconnectWork = nil; self?.reconnect() }
        reconnectWork = work
        DispatchQueue.main.asyncAfter(deadline:.now()+delay,execute:work)
    }
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String:Any]) {
        guard let id = UserDefaults.standard.string(forKey:phoneIDKey),
              let restored = (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral])?.first(where:{$0.identifier.uuidString == id}) else {
            // Recreate the saved-peer scan after centralManagerDidUpdateState.
            central.stopScan();return
        }
        peripheral = restored;restored.delegate = self
        trace("restore.\(restored.state.rawValue)")
        // Keep the OS-retained link/subscription. Re-discover it and perform a fresh
        // pinned-key handshake after poweredOn; process-lost keys are never reused.
        switch restored.state {
        case .connected: status = "저장된 휴대폰 연결 복원 중"
        case .connecting: status = "저장된 휴대폰 연결 복원 중";scheduleDiscoveryFallback()
        case .disconnected: resetSession();reconnect()
        case .disconnecting: break
        @unknown default: resetSession();reconnect()
        }
        scheduleRecoveryRefresh()
        // Restoration may arrive after poweredOn/onAppear. Resume explicitly rather
        // than waiting for a second state callback or a foreground timer.
        DispatchQueue.main.async { [weak self] in self?.reconnect() }
    }
    func centralManager(_ central: CBCentralManager, didDiscover p: CBPeripheral, advertisementData: [String:Any], rssi RSSI: NSNumber) {
        if recoveryScanning {
            guard Date() >= nextConnectAttempt else { return }
            if let existing = peripheral, existing.identifier == p.identifier {
                if switchingFrom == nil, existing.state == .connected, stage == "waitingForService" {
                    trace("service.advertisement.retry");retryServiceDiscovery(existing)
                } else if switchingFrom == nil, existing.state == .disconnected, Date() >= nextConnectAttempt {
                    // A fresh advertisement proves proximity even if an old OS
                    // auto-reconnect flag is still set. Re-submit without cancelling.
                    autoReconnectPending = false;connectionAttemptAt = Date()
                    existing.delegate = self;manager.connect(existing,options:connectionOptions())
                    trace("recovery.advertisement.connect")
                }
                return
            }
            connect(PhoneCandidate(peripheral:p));return
        }
        if !candidates.contains(where:{$0.id == p.identifier}) { candidates.append(PhoneCandidate(peripheral:p)) }
    }
    func centralManager(_ central: CBCentralManager, didConnect p: CBPeripheral) {
        trace("connect.callback.\(p === peripheral ? "current" : "other").\(p.state.rawValue)")
        guard p.identifier == peripheral?.identifier else { cancelConnection(p,reason:"unexpected-connect"); return }
        central.stopScan();recoveryScanning = false;scanEpoch += 1
        reconnectWork?.cancel();reconnectWork = nil
        autoReconnectPending = false
        guard stage == "idle" else { return }
        beginDiscovery(p)
    }
    private func beginDiscovery(_ p: CBPeripheral) {
        guard manager.state == .poweredOn, p.state == .connected, stage == "idle" else { return }
        stage = "discovering"; connectionAttemptAt = Date()
        p.delegate = self; status = "보안 연결 준비 중"
        trace("discover.start")
        if let service = p.services?.first(where:{$0.uuid == CBUUID(string:profile.service)}),
           service.characteristics?.contains(where:{$0.uuid == CBUUID(string:profile.tx)}) == true,
           service.characteristics?.contains(where:{$0.uuid == CBUUID(string:profile.rx)}) == true {
            peripheral(p,didDiscoverCharacteristicsFor:service,error:nil)
        } else { p.discoverServices([CBUUID(string:profile.service)]) }
        let current = epoch
        DispatchQueue.main.asyncAfter(deadline:.now()+120) {
            if current == self.epoch && self.active && !self.connected && Date().timeIntervalSince(self.foregroundSince) >= 120 { self.fail("보안 연결을 다시 시도합니다.",retry:true) }
        }
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        guard p === peripheral else { return }
        lastConnectError = error.map { "\(($0 as NSError).domain):\(($0 as NSError).code):\($0.localizedDescription)" } ?? "none"
        trace("connect.failed.\((error as NSError?)?.code ?? 0)")
        fail("휴대폰에 연결하지 못했습니다.",retry:true)
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        handleDisconnect(p,error:error,isReconnecting:false)
    }
    @available(watchOS 10.0, *)
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: Error?) {
        handleDisconnect(p,error:error,isReconnecting:isReconnecting)
    }
    private func handleDisconnect(_ p: CBPeripheral, error: Error?, isReconnecting: Bool) {
        lastDisconnect = error.map { "\(($0 as NSError).domain):\(($0 as NSError).code):\($0.localizedDescription)" } ?? "none"
        trace("disconnect.\(isReconnecting ? "reconnecting" : "ended").\((error as NSError?)?.code ?? 0).\(p === peripheral ? "current" : "other").\(p.state.rawValue)")
        if p === switchingFrom {
            switchingFrom = nil
            if refreshAfterDisconnect { refreshAfterDisconnect = false;startRecoveryScan() }
            else { reconnect() }
            return
        }
        guard p.identifier == peripheral?.identifier else { return }
        reconnects += 1
        if isReconnecting {
            // Keep the same Core Bluetooth object: the system owns this reconnect
            // attempt and will report didConnect when the phone returns in range.
            resetSession(keeping:p)
            autoReconnectPending = true
            status = "휴대폰 연결 복구 중"
            startRecoveryScan()
            writeDiagnostics()
            return
        }
        resetSession(); status = "휴대폰 연결이 끊겼습니다"
        // Keep short transient losses quick; back off repeated losses rather than
        // hammering Core Bluetooth every second after a system service change.
        // Submit a native pending connect before a background callback returns;
        // a delayed app timer may not run once watchOS suspends the process.
        if !active || reconnects <= 1 {
            nextConnectAttempt = .distantPast
            reconnect()
        } else { retryConnection() }
    }
    func peripheral(_ p: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        guard p === peripheral else { return }
        if stage == "waitingForService" {
            trace("service.changed.retry");retryServiceDiscovery(p);return
        }
        guard invalidatedServices.contains(where:{$0.uuid == CBUUID(string:profile.service)}) else { return }
        trace("services.invalidated")
        guard !refreshingServices, stage != "discovering", stage != "discoveringAllServices", stage != "resubscribing" else { return }
        if connected, session != nil {
            // Android's GATT database is shared with other system services. A
            // Service Changed indication does not mean our peer process/key changed.
            // Rebind invalidated handles without discarding a healthy crypto session.
            refreshingServices = true; stage = "rediscovering"; tx = nil; rx = nil
            p.discoverServices([CBUUID(string:profile.service)])
        } else { reauthenticate(p) }
    }
    private func reauthenticate(_ p: CBPeripheral) {
        let wasWriting = writing, oldWritingEpoch = writingEpoch, oldFrame = writingFrame
        resetSession()
        peripheral = p; p.delegate = self
        writing = wasWriting; writingEpoch = oldWritingEpoch; writingFrame = oldFrame
        beginDiscovery(p)
    }
    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        guard p === peripheral else { return }
        trace("discover.services.\((error as NSError?)?.code ?? 0)")
        lastServiceDiscoveryError = error.map { "\(($0 as NSError).domain):\(($0 as NSError).code)" } ?? ""
        guard error == nil else { waitForService(p);return }
        guard let service = p.services?.first(where:{$0.uuid == CBUUID(string:profile.service)}) else {
            if stage != "discoveringAllServices" {
                // A filtered lookup can return an empty shared Android GATT
                // cache after its app server restarts. Refresh the service list
                // before deciding the trusted phone is unavailable.
                stage = "discoveringAllServices";trace("service.full.discovery")
                p.discoverServices(nil)
            } else { waitForService(p) }
            return
        }
        serviceDiscoveryWork?.cancel();serviceDiscoveryWork = nil;serviceDiscoveryAttempts = 0
        if !refreshingServices { stage = "discovering" }
        p.discoverCharacteristics([CBUUID(string:profile.tx),CBUUID(string:profile.rx)],for:service)
    }
    private func waitForService(_ p: CBPeripheral) {
        guard p === peripheral else { return }
        guard (try? WatchStore.get(peerKey)) != nil else {
            fail("FoldBridge 서비스를 찾지 못했습니다.",retry:true);return
        }
        // The phone can keep its shared LE link while FoldBridge's own service
        // is temporarily absent. Cancelling here created a tight connect/cancel
        // loop even in background, without making the service appear sooner.
        let attempts = serviceDiscoveryAttempts+1
        resetSession(keeping:p);serviceDiscoveryAttempts = attempts;serviceWaitCount += 1
        stage = "waitingForService";status = "휴대폰 연결 서비스 대기 중";lastError = ""
        let delay = min(30.0,pow(2.0,Double(min(attempts,5))))
        nextServiceDiscovery = Date().addingTimeInterval(delay)
        trace("service.wait.\(attempts)");startRecoveryScan();scheduleRecoveryRefresh()
        let current = epoch
        let work = DispatchWorkItem { [weak self, weak p] in
            guard let self, let p, self.epoch == current, self.stage == "waitingForService" else { return }
            self.retryServiceDiscovery(p)
        }
        serviceDiscoveryWork = work
        DispatchQueue.main.asyncAfter(deadline:.now()+delay,execute:work)
    }
    private func retryServiceDiscovery(_ p: CBPeripheral) {
        guard p === peripheral, stage == "waitingForService", p.state == .connected,
              manager.state == .poweredOn else { return }
        serviceDiscoveryWork?.cancel();serviceDiscoveryWork = nil
        stage = "discoveringAllServices";trace("service.wait.retry")
        p.discoverServices(nil)
    }
    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard p === peripheral else { return }
        trace("discover.characteristics.\((error as NSError?)?.code ?? 0)")
        guard error == nil else { fail("통신 채널을 열지 못했습니다.",retry:true); return }
        tx = service.characteristics?.first(where:{$0.uuid == CBUUID(string:profile.tx)})
        rx = service.characteristics?.first(where:{$0.uuid == CBUUID(string:profile.rx)})
        guard let tx, rx != nil else { fail("필요한 통신 채널이 없습니다.",retry:true); return }
        if refreshingServices {
            if tx.isNotifying { finishServiceRefresh() }
            else { p.setNotifyValue(true,for:tx) }
            return
        }
        if tx.isNotifying {
            if !active {
                // Core Bluetooth retained this monitor for background delivery.
                // Removing the last subscription here can remove the very wake
                // source needed to finish restoration. Authenticate over it.
                trace("subscribe.retained.background");beginHandshake();return
            }
            // A restored Core Bluetooth subscription can outlive the phone's process.
            // Re-write CCC explicitly so both applications agree on indication state.
            stage = "resubscribing"; p.setNotifyValue(false,for:tx)
        } else { p.setNotifyValue(true,for:tx) }
    }
    func peripheral(_ p: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard p === peripheral, characteristic === tx else { return }
        trace("subscribe.\(characteristic.isNotifying).\((error as NSError?)?.code ?? 0)")
        guard characteristic.uuid == CBUUID(string:profile.tx), error == nil, identity != nil else { fail("알림 구독을 시작하지 못했습니다.",retry:true); return }
        if refreshingServices, characteristic.isNotifying { finishServiceRefresh(); return }
        if !characteristic.isNotifying, stage == "resubscribing" {
            stage = "discovering"; p.setNotifyValue(true,for:characteristic); return
        }
        guard characteristic.isNotifying else { fail("알림 구독을 시작하지 못했습니다.",retry:true); return }
        if !active, (try? WatchStore.get(peerKey)) != nil {
            // Retain the monitor first. The phone's bootstrap indication grants
            // the background receive opportunity used for the handshake.
            stage = "awaitingBootstrap";trace("handshake.await.bootstrap")
            let current = epoch
            DispatchQueue.main.asyncAfter(deadline:.now()+2) { [weak self] in
                guard let self, self.epoch == current else { return }
                self.beginAfterBootstrap()
            }
            return
        }
        beginHandshake()
    }
    private func beginAfterBootstrap() {
        guard stage == "awaitingBootstrap", peripheral?.state == .connected else { return }
        stage = "discovering";beginHandshake()
    }
    private func finishServiceRefresh() {
        refreshingServices = false; stage = "confirm"; status = "휴대폰 연결됨"
        trace("services.rebound"); drain()
    }
    private func beginHandshake() {
        guard stage == "discovering", let identity else { return }
        ownNonce = Data((0..<32).map { _ in UInt8.random(in:0...255) }); stage = "commit"
        trace("handshake.commit")
        sendPlain(["type":"commit","v":1,"commit":Data(SHA256.hash(data:identity.publicKey.derRepresentation+ownNonce)).base64EncodedString()])
    }
    func peripheral(_ p: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard p === peripheral, characteristic === tx else { return }
        if let warning = error as? CBError, warning.code == .leGattNearBackgroundNotificationLimit {
            backgroundNotice = "백그라운드 수신 한도에 가까워졌습니다. 앱을 직접 열면 수신 기회가 갱신됩니다."
            trace("background.budget.near")
        } else if let warning = error as? CBError, warning.code == .leGattExceededBackgroundNotificationLimit {
            backgroundNotice = "watchOS 백그라운드 수신 한도에 도달했습니다. 앱을 직접 열어 알림을 동기화하세요."
            trace("background.budget.exceeded")
            completeBackgroundTasks(); return
        } else if error != nil { fail("BLE 수신이 중단되어 다시 연결합니다.",retry:true); return }
        guard characteristic.uuid == CBUUID(string:profile.tx), let frame = characteristic.value else { finishBackgroundWhenIdle(); return }
        guard frame != lastIncomingFrame else { finishBackgroundWhenIdle(); return }
        lastIncomingFrame = frame
        do {
            let data = try assembler.accept(frame)
            lastIncomingActivity = Date()
            if let data { try receive(Wire.decode(data)) }
        }
        catch {
            if stage == "commit", session == nil { assembler.reset() }
            else { fail("보안 확인 또는 데이터 검증에 실패했습니다.") }
        }
        finishBackgroundWhenIdle()
    }
    func peripheral(_ p: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard p === peripheral, characteristic.uuid == CBUUID(string:profile.rx), writing else { return }
        let current = writingEpoch == epoch, frame = writingFrame
        writing = false
        writingFrame = nil
        guard !current || error == nil else { fail("휴대폰으로 전송하지 못했습니다.",retry:true); return }
        if current, outgoing.first == frame { outgoing.removeFirst() }; drain()
        finishBackgroundWhenIdle()
    }
    private func receive(_ object: [String:Any]) throws {
        guard let identity, let type = object["type"] as? String else { throw Wire.Failure.state }
        if type == "wake", (object["v"] as? Int) == 1 {
            trace("remote.wake")
            if stage == "awaitingBootstrap" { beginAfterBootstrap();return }
            if (object["bootstrap"] as? Bool) == true, !connected,
               ["commit","reveal","confirm"].contains(stage) {
                // The first write can race the bootstrap indication. Do not
                // discard a handshake already in flight for this same link.
                trace("bootstrap.handshake.inflight");return
            }
            if let p = peripheral { reauthenticate(p) }
            return
        }
        if stage == "commit", type != "commit" { return }
        if type == "commit" {
            guard stage == "commit", (object["v"] as? Int) == 1 else { throw Wire.Failure.state }
            phoneCommit = try Wire.base64(object["commit"]); guard phoneCommit.count == 32 else { throw Wire.Failure.bounds }
            stage = "reveal"
            sendPlain(["type":"reveal","public":identity.publicKey.derRepresentation.base64EncodedString(),"nonce":ownNonce.base64EncodedString()]); return
        }
        if type == "reveal" {
            guard stage == "reveal" else { throw Wire.Failure.state }
            phonePublic = try Wire.base64(object["public"]); let nonce = try Wire.base64(object["nonce"])
            guard nonce.count == 32, Data(SHA256.hash(data:phonePublic+nonce)) == phoneCommit else { throw Wire.Failure.authentication }
            let pinned = try WatchStore.get(peerKey)
            guard pinned == nil || pinned == phonePublic else { throw Wire.Failure.authentication }
            let peer = try P256.KeyAgreement.PublicKey(derRepresentation:phonePublic)
            session = Wire.Session(shared:try identity.sharedSecretFromKeyAgreement(with:peer), watchNonce:ownNonce, phoneNonce:nonce)
            stage = "confirm"; localConfirmed = pinned != nil; remoteConfirmed = false
            code = session?.code ?? ""; status = "두 기기의 코드를 비교하세요"
            if localConfirmed { sendSecure(["type":"confirm"]) }; return
        }
        guard type == "sealed", let session else { throw Wire.Failure.authentication }
        let message = try session.open(object), event = message["type"] as? String
        lastPeerActivity = Date()
        if event == "confirm" { remoteConfirmed = true; try finishAuthentication(); return }
        guard connected else { throw Wire.Failure.authentication }
        if event == "vehicle_catalogue" {
            guard let revision = message["revision"] as? String, revision.count <= 64,
                  let state = message["status"] as? String,
                  let actions = message["actions"] as? [[String:Any]], actions.count <= 12 else { throw Wire.Failure.bounds }
            var parsed: [VehicleAction] = []
            for action in actions {
                guard let id = action["id"] as? String, id.count <= 64,
                      let label = action["label"] as? String, !label.isEmpty, label.count <= 80 else { throw Wire.Failure.bounds }
                parsed.append(VehicleAction(id:id,label:label))
            }
            vehicleRevision = revision; vehicleState = state; vehicleActions = parsed
            trace("vehicle.catalogue."+state)
            VehicleQuickRouter.shared.catalogueArrived()
            return
        }
        if event == "vehicle_result" {
            guard let id = message["id"] as? String, id == vehicleRequestID else { return }
            vehicleResult = message["status"] as? String ?? "unavailable"
            vehicleRequestID = nil; vehicleBusy = false
            trace("vehicle.result."+vehicleResult)
            if ["stale","notice_dismissed"].contains(vehicleResult) { requestVehicleControls() }
            return
        }
        if event == "refresh" || event == "reconnect" {
            remoteRefreshCount += 1; softRefreshCount += 1; pendingPing = nil
            lastError = ""; status = "휴대폰 연결됨"
            trace("remote.refresh")
            reconcileDelivered {
                self.sendSecure(["type":"state","active":self.canProcessContinuously])
                self.lastSync = .distantPast; self.synchronize(); self.writeDiagnostics()
            }
            return
        }
        if event == "refreshed" { lastError = ""; writeDiagnostics(); return }
        if event == "pong" {
            if let nonce = message["nonce"] as? String, nonce == pendingPing { pendingPing = nil; pongCount += 1 }
            writeDiagnostics(); return
        }
        if event == "ready" {
            peerSupportsLiveness = (message["liveness"] as? Int) == 1
            status = "휴대폰 연결됨"; reconcileDelivered {
                self.sendSecure(["type":"state","active":self.canProcessContinuously]); self.sendPushToken(); self.synchronize(); self.requestVehicleControls()
            }
        } else if event == "notification" { try show(message) }
    }
    func confirm() {
        guard session != nil, stage == "confirm" else { return }
        localConfirmed = true; sendSecure(["type":"confirm"])
        do { try finishAuthentication() } catch { fail("휴대폰 연결을 저장하지 못했습니다.") }
    }
    private func finishAuthentication() throws {
        guard !connected, localConfirmed, remoteConfirmed else { return }
        try WatchStore.put(peerKey,phonePublic); UserDefaults.standard.set(peripheral?.identifier.uuidString,forKey:phoneIDKey)
        connected = true; code = ""; reconnects = 0; nextConnectAttempt = .distantPast; lastError = ""; status = "휴대폰 연결됨"
        trace("authenticated")
        scheduleRecoveryRefresh()
        writeDiagnostics()
    }
    private func show(_ message: [String:Any]) throws {
        guard let id = message["id"] as? String, let revision = message["rev"] as? String,
              let title = message["title"] as? String, let body = message["body"] as? String,
              let app = message["app"] as? String, id.count <= 64, revision.count <= 64, title.count <= 160, body.count <= 1200 else { throw Wire.Failure.bounds }
        let appID = (message["app_id"] as? String).map { String($0.prefix(255)) }
        let iconKey = AppIconStore.accept(key:message["icon_key"] as? String,png:message["icon_png"] as? String)
        if seen[id] == revision {
            sendSecure(["type":"ack","id":id,"rev":revision]); return
        }
        guard !pendingReceipts.contains(where:{$0.alert.id == id && $0.revision == revision}) else { return }
        receivedCount += 1; UserDefaults.standard.set(receivedCount,forKey:"diagnosticReceived")
        pendingReceipts.append((WatchAlert(id:id,app:app,title:title,body:body,received:Date(),appID:appID,iconKey:iconKey),revision))
        writeDiagnostics()
        presentNextReceipt()
    }
    private func presentNextReceipt() {
        guard !presentingReceipt, let receipt = pendingReceipts.first else { return }
        presentingReceipt = true
        let current = epoch
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                guard current == self.epoch else { return }
                self.notificationAllowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                guard self.notificationAllowed else {
                    self.presentingReceipt = false
                    self.lastError = "알림 표시 권한이 꺼져 있습니다. ‘알림 표시 허용’을 누르거나 워치 알림 설정을 확인하세요. 미확인 알림은 휴대폰에 보관됩니다."
                    self.writeDiagnostics(); self.finishBackgroundWhenIdle(); return
                }
                self.scheduleReceipt(receipt)
            }
        }
    }
    private func scheduleReceipt(_ receipt: (alert: WatchAlert, revision: String)) {
        let current = epoch
        let alert = receipt.alert, revision = receipt.revision
        let content = UNMutableNotificationContent(); content.title = alert.app; content.subtitle = alert.title; content.body = alert.body; content.sound = .default
        // Only a cached icon opts into the finite-width compact long-look.
        // Missing icons keep the system text layout; neither path attaches media.
        content.categoryIdentifier = AppIconStore.image(for:alert.iconKey) == nil ? RelayCategory.textOnly:RelayCategory.withSourceIcon
        content.threadIdentifier = alert.appID ?? alert.app
        content.userInfo = ["fb_id":alert.id,"fb_rev":revision]
        if let iconKey = alert.iconKey { content.userInfo["fb_icon"] = iconKey }
        // App artwork is not notification media: attachments are promoted to large
        // previews and shared thumbnails by watchOS. Keep the native text payload.
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier:alert.id,content:content,trigger:nil)) { error in
            DispatchQueue.main.async {
                guard current == self.epoch else { return }
                self.presentingReceipt = false
                guard self.pendingReceipts.first?.alert.id == alert.id,
                      self.pendingReceipts.first?.revision == revision else { return }
                self.pendingReceipts.removeFirst()
                if error == nil {
                    self.scheduledCount += 1; UserDefaults.standard.set(self.scheduledCount,forKey:"diagnosticScheduled")
                    // Retain only receipt hashes; notification content belongs to Notification Center.
                    self.remember(alert.id,revision)
                    if self.connected { self.sendSecure(["type":"ack","id":alert.id,"rev":revision]) }
                } else { self.lastError = "알림 표시를 요청하지 못했습니다. 다음 동기화 때 다시 요청합니다." }
                self.writeDiagnostics()
                self.presentNextReceipt(); self.finishBackgroundWhenIdle()
            }
        }
    }
    func remember(_ id: String,_ revision: String) {
        seen[id] = revision
        seenOrder.removeAll(where:{$0 == id}); seenOrder.append(id)
        while seenOrder.count > 512 { seen.removeValue(forKey:seenOrder.removeFirst()) }
        saveReceipts()
    }
    private func saveReceipts() {
        do { try WatchStore.put("receipts",JSONEncoder().encode(ReceiptLedger(seen:seen,order:seenOrder))) }
        catch { lastError = "중복 알림 방지 상태를 저장하지 못했습니다." }
    }
    func synchronize() {
        guard connected else { reconnect(); return }
        guard Date().timeIntervalSince(lastSync) > 1 else { return }
        lastSync = Date(); sendSecure(["type":"sync"])
    }
    func requestVehicleControls() {
        guard connected, profile == .local else { return }
        sendSecure(["type":"vehicle_list"])
    }
    func dismissVehicleNotice() {
        guard connected, profile == .local, !vehicleBusy, vehicleState == "result_pending" else { return }
        let id = UUID().uuidString, current = epoch
        vehicleRequestID = id; vehicleBusy = true; vehicleResult = ""
        sendSecure(["type":"vehicle_command","id":id,"revision":vehicleRevision,"action":"dismiss_notice"])
        DispatchQueue.main.asyncAfter(deadline:.now()+15) {
            guard current == self.epoch, self.vehicleRequestID == id else { return }
            self.vehicleRequestID = nil; self.vehicleBusy = false; self.vehicleResult = "unavailable"
        }
    }
    func runVehicleAction(_ action: VehicleAction) {
        guard connected, profile == .local, !vehicleBusy, !vehicleRevision.isEmpty,
              vehicleState == "ready", vehicleActions.contains(action) else { vehicleResult = "not_ready"; return }
        let id = UUID().uuidString, current = epoch
        vehicleRequestID = id; vehicleBusy = true; vehicleResult = ""
        sendSecure(["type":"vehicle_command","id":id,"revision":vehicleRevision,"action":action.id])
        // Never automatically resend an actuator request if its reply is lost.
        DispatchQueue.main.asyncAfter(deadline:.now()+30) {
            guard current == self.epoch, self.vehicleRequestID == id else { return }
            self.vehicleRequestID = nil; self.vehicleBusy = false; self.vehicleResult = "unknown"
        }
    }
    private func reconcileDelivered(_ completion: @escaping ()->Void) {
        let current = epoch
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                guard current == self.epoch, self.connected else { return }
                for n in notifications {
                    let info = n.request.content.userInfo
                    if let id = info["fb_id"] as? String, let rev = info["fb_rev"] as? String { self.remember(id,rev) }
                }
                completion()
            }
        }
    }
    private func sendPlain(_ object: [String:Any]) {
        guard let p = peripheral, rx != nil else { return }
        do {
            let chunks = try framer.split(Wire.encode(object),maximum:p.maximumWriteValueLength(for:.withResponse))
            guard outgoing.count + chunks.count <= 2048 else { throw Wire.Failure.bounds }
            outgoing.append(contentsOf:chunks); drain()
        } catch { fail("메시지가 너무 크거나 전송할 수 없습니다.") }
    }
    private func sendSecure(_ object: [String:Any]) {
        do { if let session { sendPlain(try session.seal(object)) } } catch { fail("보안 메시지 전송 실패"); }
    }
    private func drain() {
        guard !refreshingServices, !writing, let p = peripheral, let rx, let data = outgoing.first else { return }
        writing = true; writingEpoch = epoch; writingFrame = data
        lastWriteAt = Date(); p.writeValue(data,for:rx,type:.withResponse)
        let current = epoch
        DispatchQueue.main.asyncAfter(deadline:.now()+45) {
            guard self.active, self.epoch == current, self.writing, self.outgoing.first == data,
                  Date().timeIntervalSince(self.foregroundSince) >= 45 else { return }
            self.fail("휴대폰 전송 확인 시간 초과",retry:true)
        }
    }
    func setActive(_ value: Bool) {
        let changed = active != value
        if value && changed {
            foregroundSince = Date()
            // A user opening the app must not inherit the background retry
            // delay. Clear it before resumeSavedConnection() reaches reconnect.
            reconnectWork?.cancel();reconnectWork = nil
            nextConnectAttempt = .distantPast;reconnects = 0
            if peripheral?.state == .disconnected { autoReconnectPending = false }
        }
        active = value
        if changed { trace(value ? "lifecycle.foreground" : "lifecycle.background") }
        updateMaintenanceTimer()
        if value {
            backgroundNotice = ""
            refreshNotificationSettings();resumeSavedConnection()
            beginAfterBootstrap()
            if stage == "waitingForService", let p = peripheral { retryServiceDiscovery(p) }
        }
        if connected { sendSecure(["type":"state","active":canProcessContinuously]); if value { reconcileDelivered { self.synchronize() } } }
        else { reconnect();startRecoveryScan() }
        writeDiagnostics()
    }
    func setContinuousRuntime(_ value: Bool) {
        continuousRuntime = value
        updateMaintenanceTimer()
        if connected { sendSecure(["type":"state","active":canProcessContinuously]); if value { synchronize() } }
        else if value { reconnect() }
        writeDiagnostics()
    }
    func selectProfile(_ value: PhoneProfile) {
        guard value != profile else { return }
        let old = peripheral
        reconnectWork?.cancel(); reconnectWork = nil; manager.stopScan(); resetSession()
        profile = value; UserDefaults.standard.set(value.rawValue,forKey:"phoneProfile")
        candidates.removeAll(); lastError = ""; status = "\(value.title) 연결을 선택했습니다"
        if let old, old.state != .disconnected {
            switchingFrom = old; cancelConnection(old,reason:"profile")
            DispatchQueue.main.asyncAfter(deadline:.now()+3) { [weak self, weak old] in
                guard let self, let old, self.switchingFrom === old else { return }
                self.switchingFrom = nil; self.reconnect()
            }
        } else { reconnect() }
    }
    private func updateMaintenanceTimer() {
        maintenanceTimer?.invalidate(); maintenanceTimer = nil; lastMaintenance = .distantPast
        // A requested location session is not proof that the app was scheduled.
        // Never cancel a retained BLE link because a wall-clock heartbeat expired.
        guard active || continuousRuntime else { return }
        maintenanceTimer = Timer.scheduledTimer(withTimeInterval:15,repeats:true) { [weak self] _ in self?.maintainConnection() }
    }
    func maintainConnection() {
        let now = Date()
        guard now.timeIntervalSince(lastMaintenance) >= 15 else { return }
        // A timer/location callback after suspension does not prove that the
        // preceding wall-clock interval was available to finish BLE work.
        if now.timeIntervalSince(lastMaintenance) > 45 { runtimeWindowStart = now }
        lastMaintenance = now
        // Location callbacks can recover a disconnected peer without opening the UI.
        if peripheral == nil || (peripheral?.state == .connected && stage == "idle") { reconnect() }
        if !connected {
            if let p = peripheral, p.state == .disconnected, !autoReconnectPending { resetSession();reconnect() }
            startRecoveryScan()
        }
        if stage == "waitingForService", now >= nextServiceDiscovery, let p = peripheral {
            retryServiceDiscovery(p)
        }
        // This method is already executing in an OS-granted callback/timer.
        // A running location keepalive callback must also recover stalled auth,
        // rather than waiting for the user to bring the app into foreground.
        guard canProcessContinuously else { writeDiagnostics();return }
        let recoveryFloor = max(foregroundSince,runtimeWindowStart)
        if !connected, stage != "idle", stage != "waitingForService", (try? WatchStore.get(peerKey)) != nil,
                  now.timeIntervalSince(max(connectionAttemptAt,recoveryFloor)) >= 90 {
            restartSavedConnection()
        } else if !connected, stage == "idle", peripheral?.state == .connecting,
                  now.timeIntervalSince(max(connectionAttemptAt,recoveryFloor)) >= 30 {
            startRecoveryScan()
        }
        if connected, writing, now.timeIntervalSince(max(lastWriteAt,recoveryFloor)) >= 45 {
            fail("휴대폰 전송 확인 시간 초과",retry:true)
        }
        writeDiagnostics()
    }
    func sendPushToken() {
        guard profile != .local, Bundle.main.object(forInfoDictionaryKey:"FoldBridgePushEnabled") as? Bool == true,
              connected, let data = try? WatchStore.get("push_token"), let text = String(data:data,encoding:.utf8) else { return }
        sendSecure(["type":"push_token","token":text])
    }
    func handle(_ tasks: Set<WKRefreshBackgroundTask>) {
        var needsBluetooth = false, applicationRefresh = false
        for task in tasks {
            guard task is WKBluetoothAlertRefreshBackgroundTask || task is WKApplicationRefreshBackgroundTask else {
                task.setTaskCompletedWithSnapshot(false); continue
            }
            if task is WKApplicationRefreshBackgroundTask { nextRecoveryRefresh = .distantPast; applicationRefresh = true }
            needsBluetooth = true; backgroundTasks.append(task)
            task.expirationHandler = { [weak self, weak task] in
                DispatchQueue.main.async { if let task { self?.completeBackgroundTask(task) } }
            }
            // Keep the task until transfer/notification work finishes or watchOS expires it.
        }
        guard needsBluetooth else { return }
        resumeSavedConnection()
        // The incoming characteristic callback performs the response/sync. Sending
        // control traffic here for every fragment creates unnecessary background wakes.
        if !connected { reconnect() }
        else if applicationRefresh { lastSync = .distantPast; synchronize() }
        finishBackgroundWhenIdle()
    }
    private func finishBackgroundWhenIdle() {
        backgroundIdleWork?.cancel()
        guard !backgroundTasks.isEmpty else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.connected, !self.writing, self.outgoing.isEmpty,
                  (self.pendingReceipts.isEmpty || !self.notificationAllowed), !self.assembler.hasPendingMessage else { return }
            self.completeBackgroundTasks()
        }
        backgroundIdleWork = work
        DispatchQueue.main.asyncAfter(deadline:.now()+0.5,execute:work)
    }
    private func completeBackgroundTask(_ task: WKRefreshBackgroundTask) {
        guard let index = backgroundTasks.firstIndex(where:{$0 === task}) else { return }
        backgroundTasks.remove(at:index); task.expirationHandler = nil; task.setTaskCompletedWithSnapshot(false)
    }
    private func completeBackgroundTasks() {
        backgroundIdleWork?.cancel(); backgroundIdleWork = nil
        for task in Array(backgroundTasks) { completeBackgroundTask(task) }
    }
    func forget() {
        let old = peripheral; resetSession(); reconnectWork?.cancel(); reconnectWork = nil
        manager.stopScan();recoveryScanning = false;nextRecoveryRefresh = .distantPast
        UserDefaults.standard.removeObject(forKey:phoneIDKey); WatchStore.remove(peerKey); WatchStore.remove("seen"); WatchStore.remove("inbox"); WatchStore.remove("receipts"); seen = [:]; seenOrder = []; pendingReceipts.removeAll()
        if let old { cancelConnection(old,reason:"forget") }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests();UNUserNotificationCenter.current().removeAllDeliveredNotifications(); completeBackgroundTasks(); status = "등록을 해제했습니다"
    }
    private func cancelConnection(_ p: CBPeripheral, reason: String) {
        cancellationCount += 1; lastCancellation = reason
        trace("cancel."+reason)
        manager.cancelPeripheralConnection(p)
    }
    private func resetSession(keeping retainedPeripheral: CBPeripheral? = nil) {
        serviceDiscoveryWork?.cancel();serviceDiscoveryWork = nil;serviceDiscoveryAttempts = 0
        nextServiceDiscovery = .distantPast
        peripheral?.delegate = nil
        epoch += 1; scanEpoch += 1; connected = false; peripheral = retainedPeripheral; retainedPeripheral?.delegate = self; autoReconnectPending = false; tx = nil; rx = nil; session = nil; stage = "idle"; code = ""; localConfirmed = false; remoteConfirmed = false; writing = false; writingFrame = nil; outgoing.removeAll(); assembler.reset()
        lastIncomingFrame = nil; lastSync = .distantPast
        pendingPing = nil; pingSentAt = .distantPast; lastPeerActivity = .distantPast
        peerSupportsLiveness = false; connectionAttemptAt = Date(); lastIncomingActivity = .distantPast
        refreshingServices = false
        // Notification Center keeps already presented alerts; unscheduled payloads
        // from an older connection must never be replayed after reconnection.
        pendingReceipts.removeAll();presentingReceipt = false
        if vehicleBusy { vehicleResult = "unknown" }
        vehicleRequestID = nil;vehicleBusy = false;vehicleRevision = "";vehicleActions = [];vehicleState = "loading"
    }
    func noteVehicleQuickEvent(_ event: String) { trace("vehicle.quick."+event) }
    private func writeDiagnostics() {
        let state: [String:Any] = ["updatedAt":ISO8601DateFormatter().string(from:Date()),
            "profile":profile.rawValue,"connected":connected,"status":status,"active":active,
            "build":39,"cancellationCount":cancellationCount,"lastCancellation":lastCancellation,"lastDisconnect":lastDisconnect,"process":processID,"softRefreshCount":softRefreshCount,"lastFailure":lastFailure,"failureCounts":failureCounts,"sessionGeneration":epoch,"stage":stage,"refreshCount":refreshCount,
            "serviceWaitCount":serviceWaitCount,"serviceDiscoveryAttempts":serviceDiscoveryAttempts,"lastServiceDiscoveryError":lastServiceDiscoveryError,
            "lastConnectError":lastConnectError,
            "retryDelaySeconds":max(0,nextConnectAttempt.timeIntervalSinceNow),
            "identityAvailable":identity != nil,"applicationState":WKApplication.shared().applicationState.rawValue,
            "autoReconnectPending":autoReconnectPending,"recoveryScanning":recoveryScanning,
            "peripheralState":peripheral.map { String(describing:$0.state) } ?? "none",
            "livenessSupported":peerSupportsLiveness,"awaitingPong":pendingPing != nil,
            "pongCount":pongCount,"remoteRefreshCount":remoteRefreshCount,
            "continuousRequested":continuousRuntime,"notificationAllowed":notificationAllowed,
            "received":receivedCount,"scheduled":scheduledCount,"pendingReceipts":pendingReceipts.count,
            "lastError":lastError,"backgroundNotice":backgroundNotice,
            "vehicleState":vehicleState,"vehicleActions":vehicleActions.count,"vehicleBusy":vehicleBusy,"vehicleResult":vehicleResult]
        guard let folder = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first,
              let data = try? JSONSerialization.data(withJSONObject:state,options:[.sortedKeys]) else { return }
        try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        try? data.write(to:folder.appendingPathComponent("foldbridge-status.json"),options:.atomic)
    }
    private func trace(_ event: String) {
        guard let folder = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first else { return }
        let url = folder.appendingPathComponent("foldbridge-events.json")
        var events = (try? Data(contentsOf:url)).flatMap { try? JSONSerialization.jsonObject(with:$0) as? [[String:Any]] } ?? []
        events.append(["at":ISO8601DateFormatter().string(from:Date()),"process":processID,
                       "event":event,"stage":stage,"generation":epoch,"active":active])
        if events.count > 128 { events.removeFirst(events.count-128) }
        if let data = try? JSONSerialization.data(withJSONObject:events,options:[.sortedKeys]) {
            try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            try? data.write(to:url,options:.atomic)
        }
        writeDiagnostics()
    }
    private func fail(_ text: String,retry: Bool = false) {
        trace("failure.\(text)")
        lastFailure = text; failureCounts[text,default:0] += 1
        let savedPeer = UserDefaults.standard.string(forKey:phoneIDKey) != nil && (try? WatchStore.get(peerKey)) != nil
        let shouldResume = retry || savedPeer
        let old = peripheral
        reconnectWork?.cancel();reconnectWork = nil
        manager.stopScan();recoveryScanning = false;resetSession()
        lastError = text;status = "연결 확인 필요"
        if shouldResume, let old, old.state != .disconnected {
            // Keep the cancellation callback identifiable after clearing the protocol.
            // It submits the next native connect even while the app is backgrounded.
            switchingFrom = old;refreshAfterDisconnect = false
            cancelConnection(old,reason:"failure")
            let current = epoch
            DispatchQueue.main.asyncAfter(deadline:.now()+3) { [weak self, weak old] in
                guard let self, let old, self.epoch == current, self.switchingFrom === old else { return }
                self.switchingFrom = nil;self.reconnect()
            }
        } else {
            if shouldResume {
                retryConnection()
            }
        }
        // The filtered scan is registered synchronously before the background task ends.
        if savedPeer { startRecoveryScan();scheduleRecoveryRefresh() }
        completeBackgroundTasks();writeDiagnostics()
    }
}
