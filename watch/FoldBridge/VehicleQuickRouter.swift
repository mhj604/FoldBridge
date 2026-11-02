import Foundation
import Combine

/// Runs a user-selected widget control once using a fresh authenticated catalogue.
final class VehicleQuickRouter: ObservableObject {
    static let shared = VehicleQuickRouter()
    @Published var presented = false
    @Published private(set) var requested: VehicleQuickControl?
    @Published private(set) var message = ""
    @Published private(set) var waiting = false
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
        objectWillChange.send()
    }
    func run(_ control: VehicleQuickControl) {
        presented = true
        guard !waiting, !WatchLink.shared.vehicleBusy else { return }
        requested = control;message = "갤럭시에 연결하고 제어 목록을 확인하는 중입니다.";waiting = true
        catalogueRequested = false;awaitingDispatch = false
        let token = UUID();pending = token
        WatchLink.shared.resumeSavedConnection()
        if WatchLink.shared.connected { requestCatalogue() }
        DispatchQueue.main.asyncAfter(deadline:.now()+15) { [weak self] in
            guard let self, self.pending == token, self.waiting else { return }
            self.cancelPending();self.message = "갤럭시 연결 또는 제어 목록을 받지 못했습니다. 명령은 보내지 않았습니다."
        }
    }
    private func requestCatalogue() {
        catalogueRequested = true;WatchLink.shared.requestVehicleControls()
    }
    func catalogueArrived() {
        guard waiting, catalogueRequested, let control = requested else { return }
        cancelPending()
        let link = WatchLink.shared
        guard link.vehicleState == "ready" else { message = "갤럭시의 차량 제어 설정을 확인해 주세요."; return }
        guard let mapping = mappings[control.rawValue],
              let action = link.vehicleActions.first(where:{$0.id == mapping.id && $0.label == mapping.label}) else {
            message = "빠른 제어 설정에서 이 버튼에 연결할 마이현대 항목을 지정해 주세요.";return
        }
        awaitingDispatch = true;message = "요청 전달 중"
        link.runVehicleAction(action)
    }
    func cancelPending() { pending = nil;waiting = false;catalogueRequested = false }
    func dismiss() { cancelPending();presented = false }
}
