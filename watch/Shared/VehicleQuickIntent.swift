import AppIntents
import Foundation

enum VehicleQuickControl: String, AppEnum, CaseIterable, Identifiable {
    case start, lock, hazard, unlock
    var id: String { rawValue }
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "차량 버튼"
    static var caseDisplayRepresentations: [Self:DisplayRepresentation] = [
        .start:"시동/공조 켜기", .lock:"문 잠금", .hazard:"비상등 켜기", .unlock:"문 잠금 해제"
    ]
    var title: String {
        switch self { case .start:return "시동/공조 켜기"; case .lock:return "문 잠금"; case .hazard:return "비상등 켜기"; case .unlock:return "문 잠금 해제" }
    }
    var symbol: String {
        switch self { case .start:return "power"; case .lock:return "lock.fill"; case .hazard:return "exclamationmark.triangle.fill"; case .unlock:return "lock.open.fill" }
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

/// The widget opens the control panel; opening it never invokes a vehicle button.
struct OpenVehicleControls: AppIntent {
    static var title: LocalizedStringResource = "차량 제어 열기"
    static var description = IntentDescription("FoldBridge 차량 제어 창을 엽니다.")
    static var openAppWhenRun: Bool = true
    @MainActor func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        VehicleQuickRouter.shared.openControls()
        #endif
        return .result()
    }
}

struct VehicleWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "차량 제어 위젯"
    static var description = IntentDescription("위젯을 누르면 차량 제어 창을 엽니다.")
}
