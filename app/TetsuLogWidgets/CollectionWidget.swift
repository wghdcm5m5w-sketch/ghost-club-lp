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
                .containerBackground(for: .widget) {
                    WidgetTheme.navyGradient
                }
        }
        .configurationDisplayName("コレクション")
        .description("今月の遭遇数と集めた編成数を表示します。")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

struct CollectionEntry: TimelineEntry {
    let date: Date
    let monthCount: Int        // 今月の遭遇件数
    let uniqueFormations: Int  // 遭遇済みのユニーク編成数
}

struct CollectionProvider: TimelineProvider {
    func placeholder(in context: Context) -> CollectionEntry {
        .init(date: .now, monthCount: 12, uniqueFormations: 142)
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
            return .init(date: .now, monthCount: 0, uniqueFormations: 0)
        }
        let context = ModelContext(container)

        // 今月の遭遇件数
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
        let monthPredicate = #Predicate<Sighting> { $0.date >= startOfMonth }
        let monthCount = (try? context.fetchCount(FetchDescriptor(predicate: monthPredicate))) ?? 0

        // 遭遇済みのユニーク編成数（同一編成の重複を排除）
        let all = (try? context.fetch(FetchDescriptor<Sighting>())) ?? []
        let uniqueFormations = Set(all.compactMap { $0.formation?.persistentModelID }).count

        return .init(date: .now, monthCount: monthCount, uniqueFormations: uniqueFormations)
    }
}

struct CollectionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CollectionEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("今月 \(entry.monthCount) 件")
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text("TETSULOG")
                    .font(.system(size: 10, weight: .heavy, design: .serif)).tracking(2)
                Text("今月 \(entry.monthCount) 件")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                Text("集めた編成 \(entry.uniqueFormations)").font(.caption)
            }
        default:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "tram.fill").foregroundStyle(WidgetTheme.red)
                    Text("TETSULOG")
                        .font(.system(size: 9, weight: .heavy, design: .serif)).tracking(2)
                        .foregroundStyle(WidgetTheme.creamSub)
                }
                Spacer()
                Text("\(entry.monthCount)")
                    .font(.system(size: 44, weight: .heavy, design: .serif).monospacedDigit())
                    .foregroundStyle(WidgetTheme.red)
                Text("今月の遭遇")
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(WidgetTheme.cream)
                Text("集めた編成 \(entry.uniqueFormations)")
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(WidgetTheme.creamSub)
            }
        }
    }
}
