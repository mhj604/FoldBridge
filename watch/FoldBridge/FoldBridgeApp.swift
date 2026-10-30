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
        _ = WatchLink.shared
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
    }
}

struct ContentView: View {
    @EnvironmentObject var link: WatchLink
    @StateObject private var keepAlive = LocationKeepAlive.shared
    @State private var forgetting = false
    @State private var startingLocation = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:12) {
                    Text("FOLDBRIDGE").font(.caption2.bold()).foregroundStyle(.mint)
                    Label(link.status,systemImage:link.connected ? "checkmark.circle.fill":"antenna.radiowaves.left.and.right").font(.headline)
                    Text(link.profile.title).font(.caption2).foregroundStyle(.mint)
                    Button(link.profile == .original ? "새 Local 앱 연결" : "기존 앱으로 전환") {
                        link.selectProfile(link.profile == .original ? .local : .original)
                    }.font(.caption)
                    if !link.lastError.isEmpty { Text(link.lastError).font(.caption).foregroundStyle(.orange) }
                    if !link.backgroundNotice.isEmpty { Text(link.backgroundNotice).font(.caption).foregroundStyle(.orange) }
                    if !link.code.isEmpty {
                        Text(link.code).font(.system(.largeTitle,design:.monospaced).bold())
                        Text("휴대폰과 코드가 같을 때만\n양쪽에서 확인하세요.").font(.caption)
                        Button("코드가 같습니다") { link.confirm() }.tint(.mint)
                    }
                    if !link.notificationAllowed { Button("알림 표시 허용") { link.requestNotifications() } }
                    Text("수신 \(link.receivedCount) · 알림 등록 \(link.scheduledCount)").font(.caption2).foregroundStyle(.secondary)
                    if link.connected { Button("알림 동기화") { link.synchronize() }.tint(.mint) }
                    VStack(alignment:.leading,spacing:6) {
                        Text("연결 유지 · 실험 기능").font(.caption.bold())
                        Text(keepAlive.status).font(.caption2).foregroundStyle(.secondary)
                        if let date = keepAlive.lastUpdate {
                            HStack { Text("마지막 위치 이벤트"); Text(date,style:.relative) }.font(.caption2).foregroundStyle(.secondary)
                        }
                        if keepAlive.requested {
                            Button("위치 연결 유지 중지",role:.destructive) { keepAlive.stop() }.font(.caption)
                        } else {
                            Button("위치 연결 유지 시작") { startingLocation = true }.tint(.mint)
                                .confirmationDialog("위치 권한으로 연결 유지를 시도합니다. 좌표는 저장·전송하지 않습니다. 배터리 사용이 늘 수 있고 상시 수신은 보장되지 않습니다.",isPresented:$startingLocation,titleVisibility:.visible) {
                                    Button("시작하고 위치 권한 선택") { keepAlive.start() }
                                    Button("취소",role:.cancel) {}
                                }
                        }
                    }
                    if !link.connected {
                        Button("휴대폰 찾기") { link.scan() }.tint(.mint)
                        ForEach(link.candidates) { phone in Button { link.connect(phone) } label: { VStack(alignment:.leading){Text(phone.name);Text(phone.id.uuidString.prefix(8)).font(.caption2).foregroundStyle(.secondary)} } }
                    }
                    if link.alerts.isEmpty { Text("연결 후 휴대폰에서 테스트 알림을 보내세요.").font(.caption).foregroundStyle(.secondary) }
                    ForEach(link.alerts) { alert in
                        VStack(alignment:.leading,spacing:4) {
                            Text(alert.app).font(.caption2.bold()).foregroundStyle(.mint)
                            Text(alert.title).font(.headline);Text(alert.body).font(.caption)
                            Button("워치에서 삭제",role:.destructive) { link.dismiss(alert.id) }.font(.caption2)
                        }.frame(maxWidth:.infinity,alignment:.leading).padding(10).background(.white.opacity(0.08),in:RoundedRectangle(cornerRadius:12))
                    }
                    Text("갤럭시와 Bluetooth로 직접 연결합니다. 백그라운드 수신은 watchOS 한도를 받으며, 앱을 열면 휴대폰에 남아 있는 미전달 알림을 동기화합니다.").font(.caption2).foregroundStyle(.secondary)
                    Button("휴대폰 등록 해제",role:.destructive) { forgetting = true }.font(.caption)
                }.padding(.horizontal,4)
            }.navigationTitle("알림 연결").confirmationDialog("휴대폰 등록을 해제할까요?",isPresented:$forgetting) { Button("등록 해제",role:.destructive){keepAlive.stop();link.forget()} }
        }
    }
}
