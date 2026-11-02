import SwiftUI

struct VehicleAction: Identifiable, Equatable {
    let id: String
    let label: String
}

struct VehicleControlView: View {
    @EnvironmentObject var language: AppLanguage
    @EnvironmentObject var link: WatchLink
    @ObservedObject private var router = VehicleQuickRouter.shared
    @State private var selected: VehicleAction?
    @State private var confirming = false
    private var statusText: String {
        guard link.connected else { return "먼저 갤럭시와 연결해 주세요." }
        switch link.vehicleState {
        case "ready": return "갤럭시 마이현대 위젯에 연결됐습니다."
        case "disabled": return "갤럭시 FoldBridge에서 워치 차량 제어를 켜 주세요."
        case "needs_widget": return "갤럭시 FoldBridge의 차량 제어 설정에서 마이현대 위젯을 연결해 주세요."
        case "choose_buttons": return "갤럭시에서 워치에 표시할 버튼을 선택해 주세요."
        case "no_controls": return "마이현대 위젯의 제어 버튼을 읽지 못했습니다. 갤럭시 위젯 화면을 확인해 주세요."
        case "result_pending": return "제어 버튼을 누르면 결과 안내를 닫고 선택한 제어를 전달합니다."
        case "loading": return "마이현대 위젯을 갱신하는 중입니다."
        case "busy": return "마이현대 위젯이 앞선 요청을 처리 중입니다. 잠시 후 다시 눌러 주세요."
        case "auth_required": return "마이현대 위젯에 인증 요청이 표시되었습니다. 갤럭시에서 완료해 주세요."
        default: return "갤럭시의 차량 제어 설정을 확인해 주세요."
        }
    }
    private var resultText: String {
        switch link.vehicleResult {
        case "notice_dismissed": return "결과 안내를 닫고 제어 버튼을 준비하는 중입니다."
        case "result_pending": return "제어 버튼을 누르면 결과 안내를 닫고 선택한 제어를 전달합니다."
        case "widget_invoked": return "마이현대 위젯에 전달했습니다. 실제 차량 제어 결과는 마이현대 알림에서 확인하세요."
        case "duplicate": return "이미 전달한 요청입니다. 마이현대 알림을 확인하세요."
        case "stale": return "제어 목록이 바뀌었습니다. 새 목록에서 다시 선택해 주세요."
        case "busy": return "마이현대 위젯이 앞선 요청을 처리 중입니다. 잠시 후 다시 눌러 주세요."
        case "loading": return "마이현대 위젯을 갱신하는 중입니다. 잠시 후 다시 눌러 주세요."
        case "auth_required": return "마이현대 위젯에 인증 요청이 표시되었습니다. 갤럭시에서 완료해 주세요."
        case "unknown": return "응답을 받지 못했습니다. 다시 실행하기 전에 마이현대 결과를 확인하세요."
        case "": return ""
        default: return "요청을 전달하지 못했습니다. 갤럭시의 위젯 설정과 인증을 확인해 주세요."
        }
    }
    var body: some View {
        List {
            Section {
                Label("마이현대",systemImage:"car.fill")
                Text(language.text(statusText)).font(.caption2).foregroundStyle(.secondary)
            }
            if link.connected {
                Section {
                    if link.vehicleState == "result_pending" {
                        ForEach(VehicleQuickControl.allCases) { control in
                            Button(language.text(control.title)) { router.run(control) }
                                .disabled(link.vehicleBusy || router.waiting)
                        }
                        if !router.message.isEmpty { Text(language.text(router.message)).font(.caption2) }
                    }
                    ForEach(link.vehicleActions) { action in
                        Button(action.label) { selected = action; confirming = true }
                            .disabled(link.vehicleBusy)
                    }
                    if link.vehicleBusy { ProgressView(language.text("요청 전달 중")) }
                }
            }
            if !resultText.isEmpty { Section { Text(language.text(resultText)).font(.caption2) } }
            Section {
                Button { link.requestVehicleControls() } label: {
                    Label(language.text("제어 목록 새로고침"),systemImage:"arrow.clockwise")
                }.disabled(!link.connected || link.vehicleBusy)
                Text(language.text("마이현대가 휴대폰 인증을 요구하면 갤럭시에서 완료해 주세요."))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(language.text("차량 제어"))
        .onAppear { link.requestVehicleControls() }
        .onChange(of:link.connected) { value in
            if value { link.requestVehicleControls() }
            else { confirming = false; selected = nil }
        }
        .onChange(of:link.vehicleActions) { actions in
            if let selected, !actions.contains(selected) { confirming = false; self.selected = nil }
        }
        .confirmationDialog(language.text("차량 제어"),isPresented:$confirming,titleVisibility:.visible,presenting:selected) { action in
            Button(language.text("실행")) { link.runVehicleAction(action);selected = nil }
            Button(language.text("취소"),role:.cancel) { selected = nil }
        } message: { action in
            Text(action.label+"\n"+language.text("갤럭시 마이현대 위젯에 전달합니다."))
        }
    }
}
