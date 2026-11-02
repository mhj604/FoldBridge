import Foundation
import Combine

/// Runs a user-selected widget control once using a fresh authenticated catalogue.
final class VehicleQuickRouter: ObservableObject {
    static let shared = VehicleQuickRouter()
    @Published var presented = false
    @Published private(set) var requested: VehicleQuickControl?
    @Published private(set) var message = ""
    @Published private(set) var waiting = false
    @Published private(set) var needsAssignment = false
    private var pending: UUID?
    private var catalogueRequested = false
    private var awaitingDispatch = false
    private var observations = Set<AnyCancellable>()
    private struct Mapping: Codable { let id: String; let label: String }
    private var mappingKey: String { "vehicleQuickMappings."+(UserDefaults.standard.string(forKey:"phoneID.local") ?? "unpaired") }
    private var mappings: [String:Mapping] {
        get { guard let data = UserDefaults.standard.data(forKey:mappingKey) else { return [:] };return (try? JSONDecoder().decode([String:Mapping].self,from:data)) ?? [:] }
        set { if let data = try? JSONEncoder().encode(newValue) { UserDefaults.standard.set(data,forKey:mappingKey) } }
    }
    private init() {
        WatchLink.shared.$connected.dropFirst().receive(on:DispatchQueue.main).sink { [weak self] value in
            guard let self, self.waiting else { return }
            if value && !self.catalogueRequested { self.requestCatalogue() }
        }.store(in:&observations)
        WatchLink.shared.$vehicleResult.dropFirst().receive(on:DispatchQueue.main).sink { [weak self] value in
            guard let self, self.awaitingDispatch, !value.isEmpty else { return }
            self.awaitingDispatch = false
            self.message = value == "widget_invoked" ? "마이현대 위젯에 전달했습니다. 실제 차량 제어 결과는 마이현대 알림에서 확인하세요." :
                value == "unknown" ? "응답을 받지 못했습니다. 다시 실행하기 전에 마이현대 결과를 확인하세요." : "요청을 전달하지 못했습니다. 갤럭시의 위젯 설정과 인증을 확인해 주세요."
        }.store(in:&observations)
    }
    func title(for control: VehicleQuickControl) -> String? { mappings[control.rawValue]?.label }
    func bind(_ action: VehicleAction?,to control: VehicleQuickControl) {
        var saved = mappings
        if let action { saved[control.rawValue] = Mapping(id:action.id,label:action.label) }
        else { saved.removeValue(forKey:control.rawValue) }
        mappings = saved
        if requested == control, needsAssignment {
            needsAssignment = false
            message = action == nil ? "빠른 제어 버튼 연결을 해제했습니다." : "버튼을 지정했습니다. 위젯에서 다시 누르면 전달됩니다."
        }
        WatchLink.shared.noteVehicleQuickEvent("mapping.saved")
        objectWillChange.send()
    }
    func run(_ control: VehicleQuickControl) {
        presented = true
        guard !waiting, !WatchLink.shared.vehicleBusy else { return }
        requested = control;needsAssignment = false;message = "갤럭시에 연결하고 제어 목록을 확인하는 중입니다.";waiting = true
        catalogueRequested = false;awaitingDispatch = false
        let token = UUID();pending = token
        WatchLink.shared.noteVehicleQuickEvent("tap")
        WatchLink.shared.resumeSavedConnection()
        if WatchLink.shared.connected { requestCatalogue() }
        DispatchQueue.main.asyncAfter(deadline:.now()+15) { [weak self] in
            guard let self, self.pending == token, self.waiting else { return }
            self.cancelPending();self.message = "갤럭시 연결 또는 제어 목록을 받지 못했습니다. 명령은 보내지 않았습니다."
        }
    }
    private func requestCatalogue() {
        catalogueRequested = true;WatchLink.shared.noteVehicleQuickEvent("catalogue.request");WatchLink.shared.requestVehicleControls()
    }
    func catalogueArrived() {
        guard waiting, catalogueRequested, let control = requested else { return }
        cancelPending()
        let link = WatchLink.shared
        guard link.vehicleState == "ready" else {
            switch link.vehicleState {
            case "disabled":message = "갤럭시 FoldBridge에서 워치 차량 제어를 켜 주세요."
            case "needs_widget":message = "갤럭시 FoldBridge의 차량 제어 설정에서 마이현대 위젯을 연결해 주세요."
            case "choose_buttons":message = "갤럭시에서 워치에 표시할 버튼을 선택해 주세요."
            case "no_controls":message = "갤럭시 마이현대 위젯의 차량·로그인·인증 설정을 완료해 주세요."
            case "loading":message = "갤럭시의 차량 제어 목록을 불러오는 중입니다."
            default:message = "갤럭시의 차량 제어 설정을 확인해 주세요."
            }
            link.noteVehicleQuickEvent("catalogue."+link.vehicleState);return
        }
        var mapping = mappings[control.rawValue]
        if mapping == nil {
            // Only exact, unambiguous official labels may be assigned automatically.
            // Generic toggle labels such as "시동" never select start vs stop implicitly.
            let matches = link.vehicleActions.filter { canonicalLabels(for:control).contains(normalize($0.label)) }
            if matches.count == 1 {
                bind(matches[0],to:control);mapping = mappings[control.rawValue]
            }
        }
        guard let mapping, let action = link.vehicleActions.first(where:{$0.id == mapping.id && $0.label == mapping.label}) else {
            needsAssignment = true
            message = "아래에서 이 버튼에 연결할 마이현대 항목을 선택하세요. 지정 후 위젯을 다시 누르면 전달됩니다."
            link.noteVehicleQuickEvent("mapping.required");return
        }
        awaitingDispatch = true;message = "요청 전달 중"
        link.noteVehicleQuickEvent("command.dispatch")
        link.runVehicleAction(action)
    }
    private func normalize(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }
    private func canonicalLabels(for control: VehicleQuickControl) -> Set<String> {
        switch control {
        case .start:return ["시동켜기","시동시작","원격시동","원격시동켜기","엔진시동","엔진켜기","enginestart","startengine","remotestart","start"]
        case .stop:return ["시동끄기","시동종료","원격시동끄기","원격시동종료","엔진끄기","enginestop","stopengine","stop"]
        case .lock:return ["문잠금","도어잠금","문잠그기","차문잠금","도어잠그기","doorlock","lockdoors","lock"]
        case .unlock:return ["문열기","문잠금해제","잠금해제","도어잠금해제","차문열기","문열림","doorunlock","unlockdoors","unlock"]
        }
    }
    func cancelPending() { pending = nil;waiting = false;catalogueRequested = false }
    func dismiss() { cancelPending();presented = false }
}
