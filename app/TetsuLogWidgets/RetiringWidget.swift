import WidgetKit
import SwiftUI
import SwiftData

/// 「廃車進行中」ウィジェット: 引退が近い形式を一覧。
/// 「会えるのは今のうち」の緊急性を home/lock 画面に常駐させる。
/// 本体と同じ App Group の SwiftData ストアを参照する。
struct RetiringWidget: Widget {
    let kind = "RetiringWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RetiringProvider()) { entry in
            RetiringWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetTheme.navyGradient }
        }
        .configurationDisplayName("廃車進行中")
        .description("引退が近い形式を表示します。会えるのは今のうち。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct RetiringEntry: TimelineEntry {
    let date: Date
    let total: Int           // 廃車進行中の形式数
    let names: [String]      // 代表形式名（最大4件）
}

struct RetiringProvider: TimelineProvider {
    func placeholder(in context: Context) -> RetiringEntry {
        .init(date: .now, total: 3, names: ["E217系", "189系", "205系1000番台"])
    }

    func getSnapshot(in context: Context, completion: @escaping (RetiringEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RetiringEntry>) -> Void) {
        // 廃車情報は頻繁には変わらないので6時間ごと更新
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now)!
        completion(Timeline(entries: [loadEntry()], policy: .after(next)))
    }

    private func loadEntry() -> RetiringEntry {
        guard let container = SharedStore.container else {
            return .init(date: .now, total: 0, names: [])
        }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<VehicleClass>(
            predicate: #Predicate { $0.isRetiring },
            sortBy: [SortDescriptor(\.name)]
        )
        let retiring = (try? context.fetch(descriptor)) ?? []
        return .init(date: .now, total: retiring.count,
                     names: retiring.prefix(4).map(\.name))
    }
}

struct RetiringWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RetiringEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.total > 0 ? "廃車進行 \(entry.total)形式" : "廃車進行なし")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("廃車進行中")
                    .font(.system(size: 11, weight: .heavy)).tracking(1)
                if let first = entry.names.first {
                    Text(first).font(.system(size: 15, weight: .heavy, design: .serif))
                }
                Text("\(entry.total)形式 ・ 会えるのは今のうち").font(.caption2)
            }
        case .systemMedium:
            HStack(alignment: .top, spacing: 14) {
                countBlock
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.names.prefix(4), id: \.self) { n in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9)).foregroundStyle(WidgetTheme.redLight)
                            Text(n).font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundStyle(WidgetTheme.cream).lineLimit(1)
                        }
                    }
                    if entry.names.isEmpty {
                        Text("対象なし").font(.caption).foregroundStyle(WidgetTheme.creamSub)
                    }
                }
                Spacer(minLength: 0)
            }
        default:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(WidgetTheme.redLight)
                    Text("廃車進行中")
                        .font(.system(size: 9, weight: .heavy, design: .serif)).tracking(1.5)
                        .foregroundStyle(WidgetTheme.creamSub)
                }
                Spacer()
                Text("\(entry.total)")
                    .font(.system(size: 44, weight: .heavy, design: .serif).monospacedDigit())
                    .foregroundStyle(WidgetTheme.red)
                Text("形式が引退へ").font(.system(size: 12, weight: .bold)).foregroundStyle(WidgetTheme.cream)
                if let first = entry.names.first {
                    Text(first).font(.system(size: 11, design: .serif)).foregroundStyle(WidgetTheme.creamSub).lineLimit(1)
                }
            }
        }
    }

    private var countBlock: some View {
        VStack(spacing: 2) {
            Text("\(entry.total)")
                .font(.system(size: 40, weight: .heavy, design: .serif).monospacedDigit())
                .foregroundStyle(WidgetTheme.red)
            Text("形式").font(.system(size: 11, weight: .bold)).foregroundStyle(WidgetTheme.creamSub)
        }
    }
}
