import WidgetKit
import SwiftUI
import SwiftData

/// Apple Watch コンプリケーション: 文字盤に今週の遭遇数を表示。
/// 本体と同じ CloudKit Private DB（App Group ストア）を参照する。
/// watchOS 9+ のコンプリケーションは WidgetKit の accessory ファミリで実装する。
struct SightingComplication: Widget {
    let kind = "SightingComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeekProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("今週の遭遇")
        .description("今週の遭遇数を文字盤に表示します。")
        .supportedFamilies([.accessoryCircular, .accessoryInline,
                            .accessoryRectangular, .accessoryCorner])
    }
}

struct WeekEntry: TimelineEntry {
    let date: Date
    let week: Int
    let month: Int
}

struct WeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekEntry {
        .init(date: .now, week: 5, month: 18)
    }
    func getSnapshot(in context: Context, completion: @escaping (WeekEntry) -> Void) {
        completion(load())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [load()], policy: .after(next)))
    }

    private func load() -> WeekEntry {
        guard let container = SharedStore.container else {
            return .init(date: .now, week: 0, month: 0)
        }
        let ctx = ModelContext(container)
        let cal = Calendar.current
        let weekStart = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let monthStart = cal.dateInterval(of: .month, for: .now)?.start ?? .now
        let week = (try? ctx.fetchCount(FetchDescriptor<Sighting>(
            predicate: #Predicate { $0.date >= weekStart }))) ?? 0
        let month = (try? ctx.fetchCount(FetchDescriptor<Sighting>(
            predicate: #Predicate { $0.date >= monthStart }))) ?? 0
        return .init(date: .now, week: week, month: month)
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WeekEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Label("今週 \(entry.week)", systemImage: "tram.fill")

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "tram.fill").font(.system(size: 11))
                    Text("\(entry.week)").font(.system(size: 22, weight: .heavy, design: .rounded))
                    Text("今週").font(.system(size: 9))
                }
            }

        case .accessoryCorner:
            Text("\(entry.week)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .widgetLabel("今週の遭遇 \(entry.week)件")

        default: // accessoryRectangular
            HStack(spacing: 8) {
                Image(systemName: "tram.fill").foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text("TETSULOG").font(.system(size: 9, weight: .heavy)).tracking(1)
                    Text("今週 \(entry.week)件")
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                    Text("今月 \(entry.month)件").font(.system(size: 11))
                }
            }
        }
    }
}
