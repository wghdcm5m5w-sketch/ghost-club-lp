import WidgetKit
import SwiftUI
import SwiftData

/// ホーム/ロック画面ウィジェット: 今月の遭遇数・累計編成数。
/// 本体とデータを共有するため App Group の SwiftData ストアを参照する。
struct CollectionWidget: Widget {
    let kind = "CollectionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CollectionProvider()) { entry in
            CollectionWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("コレクション")
        .description("今月の遭遇数と累計編成数を表示します。")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

struct CollectionEntry: TimelineEntry {
    let date: Date
    let monthCount: Int
    let totalFormations: Int
}

struct CollectionProvider: TimelineProvider {
    func placeholder(in context: Context) -> CollectionEntry {
        .init(date: .now, monthCount: 12, totalFormations: 248)
    }

    func getSnapshot(in context: Context, completion: @escaping (CollectionEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CollectionEntry>) -> Void) {
        let entry = loadEntry()
        // 1時間ごとに更新
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> CollectionEntry {
        guard let container = SharedStore.container else {
            return .init(date: .now, monthCount: 0, totalFormations: 0)
        }
        let context = ModelContext(container)

        // 今月の遭遇数
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
        let monthPredicate = #Predicate<Sighting> { $0.date >= startOfMonth }
        let monthCount = (try? context.fetchCount(FetchDescriptor(predicate: monthPredicate))) ?? 0

        // 遭遇済み編成数（重複排除は簡略化し総 Sighting に紐づく Formation 数で近似）
        let totalFormations = (try? context.fetchCount(FetchDescriptor<Sighting>())) ?? 0

        return .init(date: .now, monthCount: monthCount, totalFormations: totalFormations)
    }
}

struct CollectionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CollectionEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("今月 \(entry.monthCount) 編成")
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text("TetsuLog").font(.caption2).foregroundStyle(.secondary)
                Text("今月 \(entry.monthCount) 編成").font(.headline)
                Text("累計 \(entry.totalFormations) 件").font(.caption)
            }
        default:
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "tram.fill").foregroundStyle(.orange)
                Spacer()
                Text("\(entry.monthCount)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Text("今月の遭遇").font(.caption).foregroundStyle(.secondary)
                Text("累計 \(entry.totalFormations) 件")
                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
        }
    }
}
