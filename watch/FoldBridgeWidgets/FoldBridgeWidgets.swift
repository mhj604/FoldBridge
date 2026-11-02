import SwiftUI
import WidgetKit
import AppIntents

struct VehicleEntry: TimelineEntry { let date: Date }
struct VehicleProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> VehicleEntry { VehicleEntry(date:Date()) }
    func snapshot(for configuration: VehicleWidgetConfiguration,in context: Context) async -> VehicleEntry { VehicleEntry(date:Date()) }
    func timeline(for configuration: VehicleWidgetConfiguration,in context: Context) async -> Timeline<VehicleEntry> {
        Timeline(entries:[VehicleEntry(date:Date())],policy:.never)
    }
    func recommendations() -> [AppIntentRecommendation<VehicleWidgetConfiguration>] {
        [AppIntentRecommendation(intent:VehicleWidgetConfiguration(),description:widgetText("차량 제어"))]
    }
}
private func widgetText(_ value: String) -> String { NSLocalizedString(value,comment:"") }
struct VehicleWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VehicleEntry
    private let accent = Color(red:0.51,green:0.90,blue:0.82)
    var body: some View {
        Button(intent:OpenVehicleControls()) {
            Group {
                switch family {
                case .accessoryRectangular:
                    HStack(spacing:12) {
                        Image(systemName:"car.fill").font(.system(size:27,weight:.medium))
                            .frame(width:48,height:48).background(.white.opacity(0.10),in:RoundedRectangle(cornerRadius:14))
                        VStack(alignment:.leading,spacing:5) {
                            Text(widgetText("차량 제어")).font(.headline)
                            Text(widgetText("눌러서 제어 창 열기")).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength:0)
                        Image(systemName:"chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    }.frame(maxWidth:.infinity,maxHeight:.infinity)
                case .accessoryInline:
                    Label(widgetText("차량 제어"),systemImage:"car.fill")
                case .accessoryCorner:
                    Image(systemName:"car.fill").font(.title3)
                        .widgetLabel { Text(widgetText("차량 제어")) }
                default:
                    VStack(spacing:3) {
                        Image(systemName:"car.fill").font(.system(size:23,weight:.medium))
                        Text(widgetText("차량 제어")).font(.system(size:9,weight:.medium)).lineLimit(1)
                    }.frame(maxWidth:.infinity,maxHeight:.infinity)
                }
            }.foregroundStyle(accent).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(widgetText("차량 제어 열기"))
            .containerBackground(for:.widget) { Color.black }
    }
}
@main struct FoldBridgeVehicleWidget: Widget {
    let kind = "FoldBridgeVehicleControls"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind:kind,intent:VehicleWidgetConfiguration.self,provider:VehicleProvider()) { entry in
            VehicleWidgetView(entry:entry)
        }
        .configurationDisplayName("차량 제어")
        .description("위젯을 누르면 차량 제어 창을 엽니다.")
        .supportedFamilies([.accessoryRectangular,.accessoryCircular,.accessoryInline,.accessoryCorner])
    }
}
