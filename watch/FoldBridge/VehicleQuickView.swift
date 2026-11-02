import SwiftUI

struct VehicleQuickView: View {
    @EnvironmentObject var language: AppLanguage
    @EnvironmentObject var link: WatchLink
    @ObservedObject private var router = VehicleQuickRouter.shared
    private let accent = Color(red:0.51,green:0.90,blue:0.82)
    private let columns = [GridItem(.flexible(),spacing:8),GridItem(.flexible(),spacing:8)]
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:12) {
                LazyVGrid(columns:columns,spacing:8) {
                    ForEach(VehicleQuickControl.allCases) { control in
                        Button { router.run(control) } label: {
                            VStack(spacing:7) {
                                Image(systemName:control.symbol).font(.system(size:23,weight:.medium))
                                Text(language.text(control.title)).font(.caption.weight(.semibold))
                            }.frame(maxWidth:.infinity,minHeight:68)
                        }.buttonStyle(.bordered).tint(accent).disabled(router.waiting || link.vehicleBusy)
                    }
                }
                if router.waiting || link.vehicleBusy { ProgressView() }
                if !router.message.isEmpty { Text(language.text(router.message)).font(.caption2).foregroundStyle(.secondary) }
                if link.vehicleState == "result_pending" {
                    Button(language.text("안내 닫고 버튼 복구")) { router.recoverNotice() }
                        .disabled(router.waiting || link.vehicleBusy)
                }
                if router.needsAssignment, let requested = router.requested {
                    VStack(alignment:.leading,spacing:6) {
                        Text(language.text(requested.title)).font(.headline)
                        ForEach(link.vehicleActions) { action in
                            Button(action.label) { router.bind(action,to:requested) }
                                .font(.caption).tint(accent)
                        }
                    }
                }
                NavigationLink { VehicleQuickSettingsView().environmentObject(link) } label: {
                    Label(language.text("빠른 제어 설정"),systemImage:"slider.horizontal.3")
                }
                NavigationLink { VehicleControlView().environmentObject(link) } label: {
                    Text(language.text("모든 차량 제어"))
                }
            }
        }.navigationTitle(language.text("차량 제어"))
            .toolbar { ToolbarItem(placement:.cancellationAction) { Button { router.dismiss() } label: { Image(systemName:"xmark") } } }
            .onDisappear { router.cancelPending() }
    }
}
struct VehicleQuickSettingsView: View {
    @EnvironmentObject var language: AppLanguage
    @EnvironmentObject var link: WatchLink
    @ObservedObject private var router = VehicleQuickRouter.shared
    var body: some View {
        List {
            Text(language.text("각 빠른 버튼에 연결할 마이현대 항목을 한 번 선택하세요. 위젯에서 누르면 바로 전달됩니다."))
                .font(.caption2).foregroundStyle(.secondary)
            ForEach(VehicleQuickControl.allCases) { control in
                NavigationLink {
                    List {
                        ForEach(link.vehicleActions) { action in
                            Button { router.bind(action,to:control) } label: {
                                HStack { Text(action.label);if router.title(for:control) == action.label { Image(systemName:"checkmark") } }
                            }
                        }
                        Button(language.text("연결 해제"),role:.destructive) { router.bind(nil,to:control) }
                    }.navigationTitle(language.text(control.title))
                } label: {
                    VStack(alignment:.leading,spacing:3) {
                        Label(language.text(control.title),systemImage:control.symbol)
                        Text(router.title(for:control) ?? language.text("버튼 선택 필요")).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Button(language.text("제어 목록 새로고침")) { link.requestVehicleControls() }
        }.navigationTitle(language.text("빠른 제어 설정"))
            .onAppear { link.requestVehicleControls() }
    }
}
