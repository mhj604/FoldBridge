import AppIntents
import Foundation

enum VehicleQuickControl: String, AppEnum, CaseIterable, Identifiable {
    case start, stop, lock, unlock
    var id: String { rawValue }
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "차량 버튼"
    static var caseDisplayRepresentations: [Self:DisplayRepresentation] = [
        .start:"시동", .stop:"정지", .lock:"문 잠금", .unlock:"문 열기"
    ]
    var title: String {
        switch self { case .start:return "시동"; case .stop:return "정지"; case .lock:return "문 잠금"; case .unlock:return "문 열기" }
    }
    var symbol: String {
        switch self { case .start:return "power"; case .stop:return "stop.fill"; case .lock:return "lock.fill"; case .unlock:return "lock.open.fill" }
    }
}

struct RunVehicleQuickControl: AppIntent {
    static var title: LocalizedStringResource = "차량 빠른 제어"
    static var description = IntentDescription("FoldBridge의 Bluetooth 연결로 갤럭시 마이현대 제어 버튼을 실행합니다.")
    // Reuse the app's authenticated BLE connection; never create a second central in the widget.
    static var openAppWhenRun: Bool = true
    @Parameter(title:"차량 버튼") var control: VehicleQuickControl
    init() {}
    init(_ control: VehicleQuickControl) { self.control = control }
    @MainActor func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        VehicleQuickRouter.shared.run(control)
        #endif
        return .result()
    }
}

struct VehicleWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "차량 제어 위젯"
    static var description = IntentDescription("작은 컴플리케이션에서 사용할 차량 버튼을 선택합니다.")
    @Parameter(title:"차량 버튼", default:.start) var control: VehicleQuickControl
}
