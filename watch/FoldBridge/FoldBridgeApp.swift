import SwiftUI
import UIKit
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
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier:RelayCategory.textOnly,actions:[],intentIdentifiers:[],options:[]),
            UNNotificationCategory(identifier:RelayCategory.withSourceIcon,actions:[],intentIdentifiers:[],options:[])
        ])
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
    @StateObject private var language = AppLanguage.shared
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(link).environmentObject(language)
            .environment(\.locale,language.locale).onAppear {
            link.setActive(scenePhase == .active)
            if scenePhase == .active { LocationKeepAlive.shared.resumeIfRequested() }
        }.onChange(of:scenePhase) { phase in
            link.setActive(phase == .active)
            if phase == .active { LocationKeepAlive.shared.resumeIfRequested() }
        } }
        WKNotificationScene(controller:CompactNotificationController.self,category:RelayCategory.withSourceIcon)
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
                    Button { link.refreshConnection() } label: { Label(language.text("연결 새로고침"),systemImage:"arrow.triangle.2.circlepath").font(.caption) }
                        .tint(BridgeStyle.accent).frame(maxWidth:.infinity)
                    if link.connected {
                        Button { link.synchronize() } label: { Label(language.text("지금 동기화"),systemImage:"arrow.clockwise").font(.caption) }
                            .buttonStyle(.plain).foregroundStyle(BridgeStyle.accent).frame(maxWidth:.infinity).padding(.vertical,8)
                    }
                }.padding(.horizontal,3)
            }.navigationTitle("FoldBridge")
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
            Section(language.text("알림")) {
                if link.notificationAllowed { Label(language.text("표시 허용됨"),systemImage:"bell.badge.fill").foregroundStyle(BridgeStyle.accent) }
                else { Button(language.text("알림 표시 허용")) { link.requestNotifications() } }
                NavigationLink { BridgeDiagnosticsView().environmentObject(link) } label: { Label(language.text("연결 진단"),systemImage:"waveform.path.ecg") }
            }
            Section {
                Button(language.text("휴대폰 등록 해제"),role:.destructive) { forgetting = true }
                Text("FoldBridge 0.4.9").font(.caption2).foregroundStyle(.secondary)
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
                        Button { link.selectProfile(.local) } label: { HStack { Text("FoldBridge Local");if link.profile == .local { Image(systemName:"checkmark").foregroundStyle(BridgeStyle.accent) } } }
                        Button { link.selectProfile(.original) } label: { HStack { Text(language.text("이전 FoldBridge"));if link.profile == .original { Image(systemName:"checkmark").foregroundStyle(BridgeStyle.accent) } } }
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
    override func didReceive(_ notification: UNNotification) { content = notification.request.content }
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
