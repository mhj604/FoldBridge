import SwiftUI
import WidgetKit
import AppIntents

struct VehicleEntry: TimelineEntry {
    let date: Date
    let control: VehicleQuickControl
}
struct VehicleProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> VehicleEntry { VehicleEntry(date:Date(),control:.start) }
    func snapshot(for configuration: VehicleWidgetConfiguration,in context: Context) async -> VehicleEntry {
        VehicleEntry(date:Date(),control:configuration.control)
    }
    func timeline(for configuration: VehicleWidgetConfiguration,in context: Context) async -> Timeline<VehicleEntry> {
        Timeline(entries:[VehicleEntry(date:Date(),control:configuration.control)],policy:.never)
    }
    func recommendations() -> [AppIntentRecommendation<VehicleWidgetConfiguration>] {
        VehicleQuickControl.allCases.map { control in
            let configuration = VehicleWidgetConfiguration(); configuration.control = control
            return AppIntentRecommendation(intent:configuration,description:widgetText(control.title))
        }
    }
}
private func widgetText(_ value: String) -> String { NSLocalizedString(value,comment:"") }
struct VehicleWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VehicleEntry
    private let accent = Color(red:0.51,green:0.90,blue:0.82)
    private func control(_ action: VehicleQuickControl) -> some View {
        Button(intent:RunVehicleQuickControl(action)) {
            HStack(spacing:5) {
                Image(systemName:action.symbol).font(.system(size:15,weight:.semibold))
                Text(widgetText(action.title)).font(.system(size:11,weight:.semibold)).lineLimit(1).minimumScaleFactor(0.75)
            }.frame(maxWidth:.infinity,minHeight:28)
                .background(.white.opacity(0.10),in:RoundedRectangle(cornerRadius:10))
        }.buttonStyle(.plain).accessibilityLabel(widgetText(action.title))
    }
    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                VStack(alignment:.leading,spacing:4) {
                    Label(widgetText("차량 제어"),systemImage:"car.fill").font(.system(size:11,weight:.semibold)).foregroundStyle(accent)
                    HStack(spacing:5) { control(.start);control(.stop) }
                    HStack(spacing:5) { control(.lock);control(.unlock) }
                }
            case .accessoryInline:
                Button(intent:RunVehicleQuickControl(entry.control)) {
                    Label(widgetText(entry.control.title),systemImage:entry.control.symbol)
                }.buttonStyle(.plain)
            case .accessoryCorner:
                Button(intent:RunVehicleQuickControl(entry.control)) {
                    Image(systemName:entry.control.symbol).font(.title3).foregroundStyle(accent)
                }.buttonStyle(.plain).widgetLabel { Text(widgetText(entry.control.title)) }
            default:
                Button(intent:RunVehicleQuickControl(entry.control)) {
                    VStack(spacing:2) {
                        Image(systemName:entry.control.symbol).font(.system(size:20,weight:.medium))
                        Text(widgetText(entry.control.title)).font(.system(size:9,weight:.medium)).lineLimit(1)
                    }.frame(maxWidth:.infinity,maxHeight:.infinity)
                }.buttonStyle(.plain).foregroundStyle(accent)
            }
        }.containerBackground(for:.widget) { Color.black }
    }
}
@main struct FoldBridgeVehicleWidget: Widget {
    let kind = "FoldBridgeVehicleControls"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind:kind,intent:VehicleWidgetConfiguration.self,provider:VehicleProvider()) { entry in
            VehicleWidgetView(entry:entry)
        }
        .configurationDisplayName("차량 제어")
        .description("시동·정지·문 잠금·문 열기를 워치에서 바로 실행합니다.")
        .supportedFamilies([.accessoryRectangular,.accessoryCircular,.accessoryInline,.accessoryCorner])
    }
}
