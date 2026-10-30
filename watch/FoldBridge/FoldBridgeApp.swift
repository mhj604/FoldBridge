import SwiftUI
import WatchKit
import UserNotifications
import CoreLocation

// Explicitly started on the watch. Coordinates are neither inspected nor retained.
final class LocationKeepAlive: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationKeepAlive()
    @Published private(set) var requested = false
    @Published private(set) var status = "위치 기반 연결 유지 꺼짐"
    @Published private(set) var lastUpdate: Date?
    private var manager: CLLocationManager?
    private let intentKey = "locationKeepAliveEnabled"

    func preserveEnabledIntentForUpdate() {
        let authorization = CLLocationManager().authorizationStatus
        guard authorization == .authorizedWhenInUse || authorization == .authorizedAlways else { return }
        UserDefaults.standard.set(true,forKey:intentKey)
    }

    func resumeIfRequested() {
        guard !requested, UserDefaults.standard.bool(forKey:intentKey) else { return }
        start()
    }

    func start() {
        guard WKApplication.shared().applicationState == .active else { return }
        guard CLLocationManager.locationServicesEnabled() else { status = "워치의 위치 서비스를 켜 주세요."; return }
        if manager == nil {
            let locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.activityType = .other
            manager = locationManager
        }
        requested = true; lastUpdate = nil; UserDefaults.standard.set(true,forKey:intentKey)
        updateAuthorization()
    }

    func stop() {
        requested = false
        UserDefaults.standard.set(false,forKey:intentKey)
        manager?.stopUpdatingLocation()
        manager?.allowsBackgroundLocationUpdates = false
        WatchLink.shared.setContinuousRuntime(false)
        status = "위치 기반 연결 유지 꺼짐"; lastUpdate = nil
    }

    private func updateAuthorization() {
        guard requested, let manager else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            status = "워치에서 위치 권한을 선택해 주세요."
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            guard !manager.allowsBackgroundLocationUpdates else { return }
            manager.allowsBackgroundLocationUpdates = true
            manager.startUpdatingLocation()
            WatchLink.shared.setContinuousRuntime(true)
            status = "위치 세션 요청됨 · 갱신 대기"
        case .denied, .restricted:
            stop(); status = "위치 권한이 없어 연결 유지 모드를 시작하지 못했습니다."
        @unknown default:
            stop(); status = "위치 권한 상태를 확인해 주세요."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { updateAuthorization() }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard requested else { return }
        // Record callback time only, never the CLLocation objects or coordinates.
        lastUpdate = Date(); status = "위치 업데이트 수신 중"
        WatchLink.shared.maintainConnection()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard requested else { return }
        if (error as? CLError)?.code == .denied {
            stop(); status = "위치 권한이 해제되어 연결 유지 모드가 종료됐습니다."
        } else { status = "위치 업데이트 대기 중 · 계속 수신은 보장되지 않습니다." }
    }
}

final class AppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().setNotificationCategories([UNNotificationCategory(identifier:"FOLDBRIDGE_ALERT",actions:[],intentIdentifiers:[],options:[])])
        WatchLink.shared.resumeSavedConnection()
        if ProcessInfo.processInfo.environment["FOLDBRIDGE_RESUME_LOCATION"] == "1" {
            LocationKeepAlive.shared.preserveEnabledIntentForUpdate()
        }
        if Bundle.main.object(forInfoDictionaryKey:"FoldBridgePushEnabled") as? Bool == true { WKApplication.shared().registerForRemoteNotifications() }
    }
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format:"%02x",$0) }.joined()
        do { try WatchStore.put("push_token",Data(token.utf8)); WatchLink.shared.sendPushToken() }
        catch { WatchLink.shared.lastError = "Push 토큰 저장 실패" }
    }
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) { WatchLink.shared.lastError = "Push 등록 실패. 서명과 Push 설정을 확인하세요." }
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) { WatchLink.shared.handle(backgroundTasks) }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)->Void) {
        DispatchQueue.main.async {
            let info = notification.request.content.userInfo
            if let id = info["fb_id"] as? String, let revision = info["fb_rev"] as? String { WatchLink.shared.remember(id,revision) }
            completionHandler([.banner,.list,.sound])
        }
    }
}

@main struct FoldBridgeApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var link = WatchLink.shared
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(link).onAppear {
            link.setActive(scenePhase == .active)
            if scenePhase == .active { LocationKeepAlive.shared.resumeIfRequested() }
        }.onChange(of:scenePhase) { phase in
            link.setActive(phase == .active)
            if phase == .active { LocationKeepAlive.shared.resumeIfRequested() }
        } }
        WKNotificationScene(controller:RelayNotificationController.self,category:"FOLDBRIDGE_ALERT")
    }
}

private enum BridgeStyle {
    static let accent = Color(red:0.51,green:0.90,blue:0.82)
    static let surface = Color(red:0.08,green:0.12,blue:0.16)
}

struct SourceAppIcon: View {
    let key: String?
    var size: CGFloat = 32
    var body: some View {
        Group {
            if let image = AppIconStore.image(for:key) {
                Image(uiImage:image).resizable().interpolation(.high).scaledToFit()
            } else {
                Image(systemName:"app.fill").resizable().scaledToFit().foregroundStyle(BridgeStyle.accent).padding(size*0.17)
            }
        }.frame(width:size,height:size).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:size*0.23))
            .clipShape(RoundedRectangle(cornerRadius:size*0.23))
    }
}

struct ContentView: View {
    @EnvironmentObject var link: WatchLink
    @StateObject private var keepAlive = LocationKeepAlive.shared
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment:.leading,spacing:12) {
                    HStack(spacing:7) {
                        Circle().fill(link.connected ? BridgeStyle.accent:Color.secondary).frame(width:6,height:6)
                        Text(link.connected ? "휴대폰 연결됨":"연결 대기 중").font(.caption2.weight(.medium))
                        Spacer()
                        if keepAlive.requested { Image(systemName:"link").foregroundStyle(BridgeStyle.accent).accessibilityLabel("연결 유지 켜짐") }
                    }.foregroundStyle(.secondary).padding(.vertical,4)
                    if !link.code.isEmpty { PairingCodeCard().environmentObject(link) }
                    if !link.connected && link.code.isEmpty {
                        NavigationLink { PhoneConnectionView().environmentObject(link) } label: { Label("휴대폰 연결",systemImage:"plus.circle.fill") }
                            .tint(BridgeStyle.accent)
                    }
                    if !link.notificationAllowed {
                        Button("알림 표시 허용") { link.requestNotifications() }.tint(BridgeStyle.accent)
                    }
                    if !link.lastError.isEmpty { Text(link.lastError).font(.caption2).foregroundStyle(.orange) }
                    VStack(spacing:10) {
                        Image(systemName:"bell.badge").font(.title2).foregroundStyle(BridgeStyle.accent)
                        Text("알림은 알림 센터에서").font(.headline).multilineTextAlignment(.center)
                        Text("화면 위에서 아래로 쓸어내려 확인하세요.\n이 앱에는 알림 내용을 보관하지 않아요.")
                            .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.frame(maxWidth:.infinity).padding(.vertical,22).padding(.horizontal,10)
                        .background(BridgeStyle.surface,in:RoundedRectangle(cornerRadius:18))
                    if link.connected {
                        Button { link.synchronize() } label: { Label("지금 동기화",systemImage:"arrow.clockwise").font(.caption) }
                            .buttonStyle(.plain).foregroundStyle(BridgeStyle.accent).frame(maxWidth:.infinity).padding(.vertical,8)
                    }
                }.padding(.horizontal,3)
            }.navigationTitle("FoldBridge")
                .toolbar { ToolbarItem(placement:.topBarTrailing) {
                    NavigationLink { BridgeSettingsView().environmentObject(link) } label: { Image(systemName:"gearshape").accessibilityLabel("설정") }
                } }
        }.tint(BridgeStyle.accent)
    }
}

struct PairingCodeCard: View {
    @EnvironmentObject var link: WatchLink
    var body: some View {
        VStack(spacing:9) {
            Text("휴대폰과 코드를 비교하세요").font(.caption2).foregroundStyle(.secondary)
            Text(link.code).font(.system(size:29,weight:.semibold,design:.monospaced)).tracking(2)
            Button("코드가 같아요") { link.confirm() }.tint(BridgeStyle.accent)
        }.padding(12).background(BridgeStyle.surface,in:RoundedRectangle(cornerRadius:18))
    }
}

struct BridgeSettingsView: View {
    @EnvironmentObject var link: WatchLink
    @StateObject private var keepAlive = LocationKeepAlive.shared
    @State private var startingLocation = false
    @State private var forgetting = false
    var body: some View {
        List {
            Section("연결") {
                NavigationLink { PhoneConnectionView().environmentObject(link) } label: { Label("휴대폰",systemImage:"iphone") }
                Toggle("연결 유지",isOn:Binding(get:{keepAlive.requested},set:{if $0 { startingLocation = true } else { keepAlive.stop() }}))
                    .tint(BridgeStyle.accent)
                Text("위치 세션으로 연결 유지를 시도합니다. 배터리 사용이 늘 수 있고 상시 수신은 보장되지 않습니다.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Section("알림") {
                if link.notificationAllowed { Label("표시 허용됨",systemImage:"bell.badge.fill").foregroundStyle(BridgeStyle.accent) }
                else { Button("알림 표시 허용") { link.requestNotifications() } }
                NavigationLink { BridgeDiagnosticsView().environmentObject(link) } label: { Label("연결 진단",systemImage:"waveform.path.ecg") }
            }
            Section {
                Button("휴대폰 등록 해제",role:.destructive) { forgetting = true }
                Text("FoldBridge 0.2.4").font(.caption2).foregroundStyle(.secondary)
            }
        }.navigationTitle("설정")
            .confirmationDialog("연결 유지를 시작할까요?",isPresented:$startingLocation,titleVisibility:.visible) {
                Button("시작") { keepAlive.start() }
                Button("취소",role:.cancel) {}
            } message: { Text("위치 업데이트로 백그라운드 실행을 시도합니다. 좌표는 저장하거나 전송하지 않습니다.") }
            .confirmationDialog("휴대폰 등록을 해제할까요?",isPresented:$forgetting) {
                Button("등록 해제",role:.destructive) { keepAlive.stop();link.forget() }
            }
    }
}

struct PhoneConnectionView: View {
    @EnvironmentObject var link: WatchLink
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:13) {
                Text(link.status).font(.headline)
                Text(link.profile.title).font(.caption2).foregroundStyle(.secondary)
                if !link.code.isEmpty { PairingCodeCard().environmentObject(link) }
                if !link.connected {
                    Button { link.scan() } label: { Label("휴대폰 찾기",systemImage:"magnifyingglass") }.tint(BridgeStyle.accent)
                    ForEach(link.candidates) { phone in
                        Button { link.connect(phone) } label: { Label(phone.name,systemImage:"iphone") }
                    }
                    Text("휴대폰에서 ‘새 워치 등록’을 누른 뒤 선택해 주세요.").font(.caption2).foregroundStyle(.secondary)
                }
                if !link.lastError.isEmpty { Text(link.lastError).font(.caption2).foregroundStyle(.orange) }
                NavigationLink("연결할 앱 선택") {
                    List {
                        Button { link.selectProfile(.local) } label: { HStack { Text("FoldBridge Local");if link.profile == .local { Image(systemName:"checkmark").foregroundStyle(BridgeStyle.accent) } } }
                        Button { link.selectProfile(.original) } label: { HStack { Text("이전 FoldBridge");if link.profile == .original { Image(systemName:"checkmark").foregroundStyle(BridgeStyle.accent) } } }
                    }.navigationTitle("연결 앱")
                }.font(.caption)
            }
        }.navigationTitle("휴대폰")
    }
}

struct BridgeDiagnosticsView: View {
    @EnvironmentObject var link: WatchLink
    @StateObject private var keepAlive = LocationKeepAlive.shared
    var body: some View {
        List {
            LabeledContent("수신",value:"\(link.receivedCount)")
            LabeledContent("알림 등록",value:"\(link.scheduledCount)")
            Text(link.status).font(.caption)
            Text(keepAlive.status).font(.caption)
            if let time = keepAlive.lastUpdate { Text(time,style:.relative).font(.caption2) }
            if !link.backgroundNotice.isEmpty { Text(link.backgroundNotice).font(.caption2).foregroundStyle(.orange) }
            if !link.lastError.isEmpty { Text(link.lastError).font(.caption2).foregroundStyle(.orange) }
        }.navigationTitle("연결 진단")
    }
}

final class RelayNotificationController: WKUserNotificationHostingController<RelayNotificationView> {
    private var content: UNNotificationContent?
    override var body: RelayNotificationView { RelayNotificationView(content:content) }
    override func didReceive(_ notification: UNNotification) { content = notification.request.content }
}

struct RelayNotificationView: View {
    let content: UNNotificationContent?
    @ScaledMetric(relativeTo:.headline) private var iconSize: CGFloat = 24

    var body: some View {
        if let content {
            // The system supplies the sash, scrolling, and dismiss control. Keep this
            // content intrinsic-height and use one leading edge for all text below it.
            VStack(alignment:.leading,spacing:4) {
                HStack(alignment:.firstTextBaseline,spacing:6) {
                    Text(content.title)
                        .font(.headline)
                        .fixedSize(horizontal:false,vertical:true)
                        .frame(maxWidth:.infinity,alignment:.leading)
                    SourceAppIcon(key:content.userInfo["fb_icon"] as? String,size:iconSize)
                        .alignmentGuide(.firstTextBaseline) { dimensions in dimensions.height*0.8 }
                }
                .padding(.bottom,2)

                if !content.subtitle.isEmpty {
                    Text(content.subtitle)
                        .font(.headline)
                        .fixedSize(horizontal:false,vertical:true)
                        .frame(maxWidth:.infinity,alignment:.leading)
                }
                if !content.body.isEmpty {
                    Text(content.body)
                        .font(.body)
                        .fixedSize(horizontal:false,vertical:true)
                        .frame(maxWidth:.infinity,alignment:.leading)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth:.infinity,alignment:.topLeading)
            .scenePadding(.horizontal)
            .padding(.bottom,8)
        }
    }
}
