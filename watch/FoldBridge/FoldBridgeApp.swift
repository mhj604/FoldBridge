import SwiftUI
import UIKit
import WatchKit
import UserNotifications
import CoreLocation
import WidgetKit

// User-enabled location activity. Coordinates are never inspected, retained or sent.
final class LocationKeepAlive: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationKeepAlive()
    @Published private(set) var requested = false
    @Published private(set) var status = "위치 기반 연결 유지 꺼짐"
    @Published private(set) var lastUpdate: Date?
    private var manager: CLLocationManager?
    private var activity: CLBackgroundActivitySession?
    private var updatesTask: Task<Void,Never>?
    private var diagnosticsTask: Task<Void,Never>?
    private var generation = 0
    private var createdInBackground = false
    private var foregroundRejoined = false
    private var sessionNeedsForeground = false
    private let intentKey = "locationKeepAliveEnabled"
    private let preparedKey = "locationActivityPrepared.v1"

    func preserveEnabledIntentForUpdate() {
        let authorization = CLLocationManager().authorizationStatus
        guard authorization == .authorizedWhenInUse || authorization == .authorizedAlways else { return }
        UserDefaults.standard.set(true,forKey:intentKey)
    }

    // Must run immediately on launch, before deferred UI/notification setup.
    // Rejoining an existing native activity is allowed from the background;
    // a preference alone cannot create a new active background session.
    func restoreAtLaunch() {
        guard UserDefaults.standard.bool(forKey:intentKey) else { return }
        let authorization = CLLocationManager().authorizationStatus
        guard authorization == .authorizedWhenInUse || authorization == .authorizedAlways else { return }
        requested = true
        guard UserDefaults.standard.bool(forKey:preparedKey) else {
            status = "연결 유지 준비를 위해 앱을 한 번 열어 주세요."
            WatchLink.shared.noteLocationActivity("needs-foreground-setup")
            return
        }
        beginActivity(restoring:true)
    }

    func resumeIfRequested() {
        guard UserDefaults.standard.bool(forKey:intentKey), WKApplication.shared().applicationState == .active else { return }
        start()
    }

    func start() {
        guard WKApplication.shared().applicationState == .active else { return }
        guard CLLocationManager.locationServicesEnabled() else { status = "워치의 위치 서비스를 켜 주세요."; return }
        if manager == nil {
            let locationManager = CLLocationManager()
            manager = locationManager;locationManager.delegate = self
        }
        requested = true;UserDefaults.standard.set(true,forKey:intentKey)
        updateAuthorization()
    }

    func stop() {
        requested = false;generation += 1
        UserDefaults.standard.set(false,forKey:intentKey)
        UserDefaults.standard.set(false,forKey:preparedKey)
        updatesTask?.cancel();updatesTask = nil
        diagnosticsTask?.cancel();diagnosticsTask = nil
        activity?.invalidate();activity = nil
        WatchLink.shared.setContinuousRuntime(false)
        WatchLink.shared.noteLocationActivity("off")
        status = "위치 기반 연결 유지 꺼짐";lastUpdate = nil
    }

    private func updateAuthorization() {
        guard requested, let manager else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            guard WKApplication.shared().applicationState == .active else { return }
            status = "워치에서 위치 권한을 선택해 주세요."
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            guard WKApplication.shared().applicationState == .active else { return }
            // A pending restoration object can be insufficiently-in-use. Rejoin
            // once when directly used, without invalidating the native activity.
            if createdInBackground && !foregroundRejoined {
                beginActivity(restoring:false,replacing:true);return
            }
            if activity == nil { beginActivity(restoring:false) }
            else { startUpdatesIfNeeded() }
        case .denied, .restricted:
            stop();status = "위치 권한이 없어 연결 유지 모드를 시작하지 못했습니다."
        @unknown default:
            stop();status = "위치 권한 상태를 확인해 주세요."
        }
    }

    private func beginActivity(restoring: Bool, replacing: Bool = false) {
        guard activity == nil || replacing else { return }
        if replacing {
            generation += 1
            updatesTask?.cancel();updatesTask = nil
            diagnosticsTask?.cancel();diagnosticsTask = nil
        }
        createdInBackground = WKApplication.shared().applicationState != .active
        foregroundRejoined = !createdInBackground
        sessionNeedsForeground = false
        // Keep this object for the full user-enabled feature span. Never put it
        // in a local scope whose deallocation would invalidate the activity.
        activity = CLBackgroundActivitySession()
        if !createdInBackground { UserDefaults.standard.set(true,forKey:preparedKey) }
        status = restoring ? "위치 연결 유지 세션 복원 요청됨":"위치 세션 요청됨 · 갱신 대기"
        WatchLink.shared.noteLocationActivity(restoring ? "restore-requested":"requested")
        WatchLink.shared.setContinuousRuntime(true)
        startUpdatesIfNeeded()
        if #available(watchOS 11.0, *), let activity {
            let current = generation
            diagnosticsTask = Task { @MainActor [weak self] in
                do {
                    for try await diagnostic in activity.diagnostics {
                        guard let self, self.requested, self.generation == current, !Task.isCancelled else { return }
                        if diagnostic.authorizationDenied || diagnostic.authorizationRestricted {
                            self.stop();self.status = "위치 권한이 없어 연결 유지 모드를 시작하지 못했습니다.";return
                        }
                        if diagnostic.authorizationDeniedGlobally || diagnostic.insufficientlyInUse {
                            self.sessionNeedsForeground = true
                            self.status = diagnostic.authorizationDeniedGlobally ? "워치의 위치 서비스를 켜 주세요.":"연결 유지 준비를 위해 앱을 한 번 열어 주세요."
                            WatchLink.shared.setContinuousRuntime(false)
                            WatchLink.shared.noteLocationActivity(diagnostic.authorizationDeniedGlobally ? "location-disabled":"needs-foreground")
                        } else {
                            self.sessionNeedsForeground = false
                            WatchLink.shared.setContinuousRuntime(true)
                            WatchLink.shared.noteLocationActivity("eligible")
                        }
                    }
                } catch {
                    guard let self, self.generation == current, !Task.isCancelled else { return }
                    WatchLink.shared.noteLocationActivity("diagnostics-ended")
                }
            }
        }
    }

    private func startUpdatesIfNeeded() {
        guard updatesTask == nil, activity != nil else { return }
        let current = generation
        updatesTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    // Ignore the entire update value: no coordinates are read.
                    for try await _ in CLLocationUpdate.liveUpdates() {
                        guard let self, self.requested, self.generation == current, !Task.isCancelled else { return }
                        self.lastUpdate = Date()
                        if !self.sessionNeedsForeground { self.status = "위치 업데이트 수신 중" }
                        WatchLink.shared.noteLocationActivity(callback:true)
                        WatchLink.shared.maintainConnection()
                    }
                } catch {
                    guard let self, self.requested, self.generation == current, !Task.isCancelled else { return }
                    self.status = "위치 업데이트 대기 중 · 계속 수신은 보장되지 않습니다."
                    WatchLink.shared.noteLocationActivity("updates-waiting")
                }
                guard let self, self.requested, self.generation == current, !Task.isCancelled else { return }
                // A transient stream end must not turn off the saved intent.
                // This delay only runs while scheduled; it cannot wake watchOS.
                do { try await Task.sleep(nanoseconds:5_000_000_000) } catch { return }
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { updateAuthorization() }
}

final class AppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching() {
        WatchLink.shared.noteDisplayEvent("delegate.launch")
        let location = LocationKeepAlive.shared
        if ProcessInfo.processInfo.environment["FOLDBRIDGE_RESUME_LOCATION"] == "1" {
            location.preserveEnabledIntentForUpdate()
        }
        location.restoreAtLaunch()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier:RelayCategory.textOnly,actions:[],intentIdentifiers:[],options:[]),
            UNNotificationCategory(identifier:RelayCategory.withSourceIcon,actions:[],intentIdentifiers:[],options:[])
        ])
        WatchLink.shared.resumeSavedConnection()
        if UserDefaults.standard.string(forKey:"vehicleWidgetLayout") != "panel.v1" {
            UserDefaults.standard.set("panel.v1",forKey:"vehicleWidgetLayout")
            WidgetCenter.shared.invalidateConfigurationRecommendations()
            WidgetCenter.shared.reloadTimelines(ofKind:"FoldBridgeVehicleControls")
        }
        if Bundle.main.object(forInfoDictionaryKey:"FoldBridgePushEnabled") as? Bool == true { WKApplication.shared().registerForRemoteNotifications() }
    }
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format:"%02x",$0) }.joined()
        do { try WatchStore.put("push_token",Data(token.utf8)); WatchLink.shared.sendPushToken() }
        catch { WatchLink.shared.lastError = "Push 토큰 저장 실패" }
    }
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) { WatchLink.shared.lastError = "Push 등록 실패. 서명과 Push 설정을 확인하세요." }
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        if backgroundTasks.contains(where: { $0 is WKBluetoothAlertRefreshBackgroundTask }) { WatchLink.shared.noteDisplayEvent("background.bluetooth-task") }
        if backgroundTasks.contains(where: { $0 is WKApplicationRefreshBackgroundTask }) { WatchLink.shared.noteDisplayEvent("background.refresh-task") }
        WatchLink.shared.handle(backgroundTasks)
    }
    func handleUserActivity(_ userInfo: [AnyHashable:Any]?) { WatchLink.shared.noteDisplayEvent("entry.user-activity-dictionary") }
    func handle(_ userActivity: NSUserActivity) { WatchLink.shared.noteDisplayEvent("entry.user-activity") }
    func handleRemoteNowPlayingActivity() { WatchLink.shared.noteDisplayEvent("entry.remote-now-playing") }
    func applicationWillEnterForeground() { WatchLink.shared.noteDisplayEvent("delegate.will-enter-foreground") }
    func applicationDidBecomeActive() { WatchLink.shared.noteDisplayEvent("delegate.did-become-active") }
    func applicationWillResignActive() { WatchLink.shared.noteDisplayEvent("delegate.will-resign-active") }
    func applicationDidEnterBackground() { WatchLink.shared.noteDisplayEvent("delegate.did-enter-background") }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping ()->Void) {
        let isRenewal = response.notification.request.identifier.hasPrefix("renewal-")
        let event = response.actionIdentifier == UNNotificationDefaultActionIdentifier ? (isRenewal ? "notification.renewal.open":"notification.open") :
            response.actionIdentifier == UNNotificationDismissActionIdentifier ? "notification.dismiss":"notification.action"
        DispatchQueue.main.async {
            WatchLink.shared.noteDisplayEvent(event)
            completionHandler()
        }
    }
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
    @StateObject private var language = AppLanguage.shared
    @StateObject private var vehicleQuick = VehicleQuickRouter.shared
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(link).environmentObject(language)
            .environment(\.locale,language.locale)
            .sheet(isPresented:$vehicleQuick.presented,onDismiss:{link.noteDisplayEvent("vehicle.panel.dismiss");vehicleQuick.cancelPending()}) {
                NavigationStack { VehicleQuickView().environmentObject(link).environmentObject(language) }
                    .environment(\.locale,language.locale)
            }.onAppear {
            link.noteDisplayEvent("view.main.appear")
            recordScenePhase(scenePhase)
            link.setActive(scenePhase == .active)
            if scenePhase == .active { LocationKeepAlive.shared.resumeIfRequested() }
        }.onChange(of:scenePhase) { phase in
            recordScenePhase(phase)
            link.setActive(phase == .active)
            if phase == .active { LocationKeepAlive.shared.resumeIfRequested() }
        } }
        WKNotificationScene(controller:CompactNotificationController.self,category:RelayCategory.withSourceIcon)
    }
    private func recordScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active: link.noteScenePhase("active")
        case .inactive: link.noteScenePhase("inactive")
        case .background: link.noteScenePhase("background")
        @unknown default: link.noteScenePhase("unknown")
        }
    }
}

private enum BridgeStyle {
    static let accent = Color(red:0.51,green:0.90,blue:0.82)
    static let surface = Color(red:0.08,green:0.12,blue:0.16)
}

struct ContentView: View {
    @EnvironmentObject var language: AppLanguage
    @EnvironmentObject var link: WatchLink
    @StateObject private var keepAlive = LocationKeepAlive.shared
    @State private var displayIssueRecorded = false
    private func vehicleQuickMenu() { VehicleQuickRouter.shared.openControls() }
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment:.leading,spacing:12) {
                    HStack(spacing:7) {
                        Circle().fill(link.connected ? BridgeStyle.accent:Color.secondary).frame(width:6,height:6)
                        Text(link.connected ? language.text("휴대폰 연결됨"):language.text("연결 대기 중")).font(.caption2.weight(.medium))
                        Spacer()
                        if keepAlive.requested { Image(systemName:"link").foregroundStyle(BridgeStyle.accent).accessibilityLabel(language.text("연결 유지 켜짐")) }
                    }.foregroundStyle(.secondary).padding(.vertical,4)
                    if !link.code.isEmpty { PairingCodeCard().environmentObject(link) }
                    if !link.connected && link.code.isEmpty {
                        NavigationLink { PhoneConnectionView().environmentObject(link) } label: { Label(language.text("휴대폰 연결"),systemImage:"plus.circle.fill") }
                            .tint(BridgeStyle.accent)
                    }
                    if !link.notificationAllowed {
                        Button(language.text("알림 표시 허용")) { link.requestNotifications() }.tint(BridgeStyle.accent)
                    }
                    if !link.lastError.isEmpty { Text(language.text(link.lastError)).font(.caption2).foregroundStyle(.orange) }
                    VStack(spacing:10) {
                        Image(systemName:"bell.badge").font(.title2).foregroundStyle(BridgeStyle.accent)
                        Text(language.text("알림은 알림 센터에서")).font(.headline).multilineTextAlignment(.center)
                        Text(language.text("화면 위에서 아래로 쓸어내려 확인하세요.\n이 앱에는 알림 내용을 보관하지 않아요."))
                            .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.frame(maxWidth:.infinity).padding(.vertical,22).padding(.horizontal,10)
                        .background(BridgeStyle.surface,in:RoundedRectangle(cornerRadius:18))
                    if link.profile == .local {
                        Button { vehicleQuickMenu() } label: {
                            Label(language.text("차량 제어"),systemImage:"car.fill")
                        }.tint(BridgeStyle.accent)
                    }
                    Button { link.refreshConnection() } label: { Label(language.text("연결 새로고침"),systemImage:"arrow.triangle.2.circlepath").font(.caption) }
                        .tint(BridgeStyle.accent).frame(maxWidth:.infinity)
                    if link.connected {
                        Button { link.synchronize() } label: { Label(language.text("지금 동기화"),systemImage:"arrow.clockwise").font(.caption) }
                            .buttonStyle(.plain).foregroundStyle(BridgeStyle.accent).frame(maxWidth:.infinity).padding(.vertical,8)
                    }
                    Button {
                        link.recordDisplayIncident();displayIssueRecorded = true
                    } label: {
                        Label(language.text(displayIssueRecorded ? "화면 기록 저장됨":"화면 문제 기록"),systemImage:"note.text")
                            .font(.caption2)
                    }.buttonStyle(.plain).foregroundStyle(.secondary).frame(maxWidth:.infinity).padding(.vertical,6)
                }.padding(.horizontal,3)
            }.navigationTitle("WatchBridge")
                .toolbar { ToolbarItem(placement:.topBarTrailing) {
                    NavigationLink { BridgeSettingsView().environmentObject(link) } label: { Image(systemName:"gearshape").accessibilityLabel(language.text("설정")) }
                } }
        }.tint(BridgeStyle.accent)
    }
}

struct PairingCodeCard: View {
    @EnvironmentObject var language: AppLanguage
    @EnvironmentObject var link: WatchLink
    var body: some View {
        VStack(spacing:9) {
            Text(language.text("휴대폰과 코드를 비교하세요")).font(.caption2).foregroundStyle(.secondary)
            Text(link.code).font(.system(size:29,weight:.semibold,design:.monospaced)).tracking(2)
            Button(language.text("코드가 같아요")) { link.confirm() }.tint(BridgeStyle.accent)
        }.padding(12).background(BridgeStyle.surface,in:RoundedRectangle(cornerRadius:18))
    }
}

struct BridgeSettingsView: View {
    @EnvironmentObject var language: AppLanguage
    @EnvironmentObject var link: WatchLink
    @StateObject private var keepAlive = LocationKeepAlive.shared
    @State private var startingLocation = false
    @State private var forgetting = false
    var body: some View {
        List {
            Section(language.text("언어 / Language")) {
                Picker(language.text("언어 / Language"),selection:$language.selection) {
                    Text(language.text("시스템 설정")).tag("system")
                    Text("한국어").tag("ko")
                    Text("English").tag("en")
                }
            }
            Section(language.text("연결")) {
                NavigationLink { PhoneConnectionView().environmentObject(link) } label: { Label(language.text("휴대폰"),systemImage:"iphone") }
                Button { link.refreshConnection() } label: { Label(language.text("연결 새로고침"),systemImage:"arrow.triangle.2.circlepath") }
                Toggle(language.text("연결 유지"),isOn:Binding(get:{keepAlive.requested},set:{if $0 { startingLocation = true } else { keepAlive.stop() }}))
                    .tint(BridgeStyle.accent)
                Text(language.text("위치 세션으로 연결 유지를 시도합니다. 배터리 사용이 늘 수 있고 상시 수신은 보장되지 않습니다."))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Section(language.text("백그라운드 사용")) {
                Text(language.text("시계 화면에서도 알림 수신과 자동 재연결을 이어갑니다."))
                    .font(.caption2).foregroundStyle(.secondary)
                Text(language.text("앱이 다시 나타나면 워치 설정 → 일반 → 시계로 돌아가기 → WatchBridge에서 ‘사용자화 → 항상’을 선택하세요. ‘앱으로 돌아가기’가 있으면 끄세요."))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Section(language.text("알림")) {
                if link.notificationAllowed { Label(language.text("표시 허용됨"),systemImage:"bell.badge.fill").foregroundStyle(BridgeStyle.accent) }
                else { Button(language.text("알림 표시 허용")) { link.requestNotifications() } }
                NavigationLink { BridgeDiagnosticsView().environmentObject(link) } label: { Label(language.text("연결 진단"),systemImage:"waveform.path.ecg") }
            }
            Section {
                Button(language.text("휴대폰 등록 해제"),role:.destructive) { forgetting = true }
                Text("WatchBridge " + (Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "")).font(.caption2).foregroundStyle(.secondary)
            }
        }.navigationTitle(language.text("설정"))
            .confirmationDialog(language.text("연결 유지를 시작할까요?"),isPresented:$startingLocation,titleVisibility:.visible) {
                Button(language.text("시작")) { keepAlive.start() }
                Button(language.text("취소"),role:.cancel) {}
            } message: { Text(language.text("위치 업데이트로 백그라운드 실행을 시도합니다. 좌표는 저장하거나 전송하지 않습니다.")) }
            .confirmationDialog(language.text("휴대폰 등록을 해제할까요?"),isPresented:$forgetting) {
                Button(language.text("등록 해제"),role:.destructive) { keepAlive.stop();link.forget() }
            }
    }
}

struct PhoneConnectionView: View {
    @EnvironmentObject var language: AppLanguage
    @EnvironmentObject var link: WatchLink
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:13) {
                Text(language.text(link.status)).font(.headline)
                Text(language.text(link.profile.title)).font(.caption2).foregroundStyle(.secondary)
                if !link.code.isEmpty { PairingCodeCard().environmentObject(link) }
                if !link.connected {
                    Button { link.scan() } label: { Label(language.text("휴대폰 찾기"),systemImage:"magnifyingglass") }.tint(BridgeStyle.accent)
                    ForEach(link.candidates) { phone in
                        Button { link.connect(phone) } label: { Label(phone.name,systemImage:"iphone") }
                    }
                    Text(language.text("휴대폰에서 ‘새 워치 등록’을 누른 뒤 선택해 주세요.")).font(.caption2).foregroundStyle(.secondary)
                }
                if !link.lastError.isEmpty { Text(language.text(link.lastError)).font(.caption2).foregroundStyle(.orange) }
                NavigationLink(language.text("연결할 앱 선택")) {
                    List {
                        Button { link.selectProfile(.local) } label: { HStack { Text("WatchBridge");if link.profile == .local { Image(systemName:"checkmark").foregroundStyle(BridgeStyle.accent) } } }
                        Button { link.selectProfile(.original) } label: { HStack { Text(language.text("이전 WatchBridge"));if link.profile == .original { Image(systemName:"checkmark").foregroundStyle(BridgeStyle.accent) } } }
                    }.navigationTitle(language.text("연결 앱"))
                }.font(.caption)
            }
        }.navigationTitle(language.text("휴대폰"))
    }
}

struct BridgeDiagnosticsView: View {
    @EnvironmentObject var language: AppLanguage
    @EnvironmentObject var link: WatchLink
    @StateObject private var keepAlive = LocationKeepAlive.shared
    var body: some View {
        List {
            LabeledContent(language.text("수신"),value:"\(link.receivedCount)")
            LabeledContent(language.text("알림 등록"),value:"\(link.scheduledCount)")
            Text(language.text(link.status)).font(.caption)
            Text(language.text(keepAlive.status)).font(.caption)
            if let time = keepAlive.lastUpdate { Text(time,style:.relative).font(.caption2) }
            if !link.backgroundNotice.isEmpty { Text(language.text(link.backgroundNotice)).font(.caption2).foregroundStyle(.orange) }
            if !link.lastError.isEmpty { Text(language.text(link.lastError)).font(.caption2).foregroundStyle(.orange) }
        }.navigationTitle(language.text("연결 진단"))
    }
}


// Only this category has a custom long-look. The system owns the popup, sash,
// Notification Center cards, scroll container, and dismiss control.
enum RelayCategory {
    static let textOnly = "FOLDBRIDGE_NATIVE_ALERT"
    static let withSourceIcon = "FOLDBRIDGE_COMPACT_ICON_ALERT"
}

final class CompactNotificationController: WKUserNotificationHostingController<CompactNotificationView> {
    private var content: UNNotificationContent?
    override var body: CompactNotificationView { CompactNotificationView(content:content) }
    override func didReceive(_ notification: UNNotification) {
        content = notification.request.content
        WatchLink.shared.noteDisplayEvent("notification.detail.received")
    }
}

struct CompactNotificationView: View {
    let content: UNNotificationContent?
    private let iconSize: CGFloat = 24
    @ScaledMetric(relativeTo:.body) private var textSize: CGFloat = 16
    private var layoutWidth: CGFloat { max(100,WKInterfaceDevice.current().screenBounds.width-32) }
    private var textWidth: CGFloat { layoutWidth }
    private var iconTop: CGFloat { (UIFont.systemFont(ofSize:textSize,weight:.semibold).lineHeight-iconSize)/2 }

    private var topAdjustment: CGFloat {
        if #available(watchOS 27.0,*) { return -13 }
        return 0
    }

    private var bottomAdjustment: CGFloat {
        if #available(watchOS 27.0,*) { return -4 }
        return 0
    }

    @ViewBuilder private func bodyText(_ value: String) -> some View {
        if #available(watchOS 26.0,*) {
            Text(value).lineHeight(.exact(points:textSize * 1.15625))
        } else {
            Text(value)
        }
    }

    var body: some View {
        if let content {
            let icon = AppIconStore.image(for:content.userInfo["fb_icon"] as? String)
            VStack(alignment:.leading,spacing:0) {
                if !content.title.isEmpty {
                    Text(content.title)
                        .font(.system(size:textSize,weight:.semibold))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal:false,vertical:true)
                        .frame(width:icon == nil ? textWidth:layoutWidth-iconSize-8,alignment:.leading)
                }
                if !content.subtitle.isEmpty {
                    Text(content.subtitle)
                        .font(.system(size:textSize,weight:.semibold))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal:false,vertical:true)
                        .frame(width:textWidth,alignment:.leading)
                }
                if !content.body.isEmpty {
                    bodyText(content.body)
                        .font(.system(size:textSize))
                        .padding(.top,-textSize/16)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal:false,vertical:true)
                        .frame(width:textWidth,alignment:.leading)
                }
            }
            .frame(width:layoutWidth,alignment:.leading)
            .frame(minHeight:icon == nil ? 0:iconSize,alignment:.topLeading)
            .overlay(alignment:.topTrailing) {
                if let icon {
                    Image(uiImage:icon)
                        .resizable().scaledToFit()
                        .frame(width:iconSize,height:iconSize)
                        .clipShape(RoundedRectangle(cornerRadius:5))
                        .offset(y:iconTop)
                        .accessibilityHidden(true)
                }
            }
            // Keep the icon outside text measurement; preserve its full rounded outline.
            .padding(.top,topAdjustment)
            .padding(.bottom,bottomAdjustment)
        }
    }
}
