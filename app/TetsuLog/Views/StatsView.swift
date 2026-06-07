import SwiftUI
import SwiftData

/// 統計タブ: 累計距離・最頻出形式・最頻出路線・月別推移など、
/// 鉄ヲタの自己満足の中核を提供する画面。
struct StatsView: View {
    @Query private var sightings: [Sighting]
    @Query private var rides: [RideSegment]
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 18, pinnedViews: []) {
                    overviewSection
                    completionSection
                    topClassesSection
                    topLinesSection
                    topStationsSection
                    monthlyChartSection
                    lastRunSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("統計")
        }
    }

    private var overview: Statistics.Overview {
        Statistics.overview(sightings: sightings, rides: rides)
    }

    // MARK: - セクション

    private var overviewSection: some View {
        let o = overview
        return statCard {
            HStack(alignment: .top, spacing: 14) {
                statTile(value: "\(o.totalSightings)", label: "遭遇")
                statTile(value: "\(o.collectedFormations)", label: "編成")
                statTile(value: String(format: "%.0f", o.totalRideKm), label: "km")
                statTile(value: String(format: "%.0f", o.totalRideHours), label: "時間")
            }
        } title: "サマリー"
    }

    private var completionSection: some View {
        let complete = classes.filter { $0.isComplete && $0.totalCount > 0 }
        let partial = classes.filter { !$0.isComplete && $0.collectedCount > 0 }
        return statCard {
            HStack {
                Label("コンプリート", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Spacer()
                Text("\(complete.count) 形式").font(.headline.monospaced())
            }
            Divider()
            HStack {
                Label("収集中", systemImage: "circle.dotted")
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(partial.count) 形式").font(.headline.monospaced())
            }
        } title: "コレクション"
    }

    private var topClassesSection: some View {
        let top = Statistics.topClasses(sightings: sightings)
        return statCard {
            if top.isEmpty {
                Text("まだ記録がありません").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(Array(top.enumerated()), id: \.offset) { idx, item in
                    HStack {
                        Text("\(idx + 1)").font(.caption.monospaced()).foregroundStyle(.secondary)
                        Text(item.name)
                        Spacer()
                        Text("\(item.count)回").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    if idx < top.count - 1 { Divider() }
                }
            }
        } title: "よく出会う形式"
    }

    private var topLinesSection: some View {
        let top = Statistics.topLines(sightings: sightings)
        return statCard {
            if top.isEmpty {
                Text("まだ記録がありません").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(Array(top.enumerated()), id: \.offset) { idx, item in
                    HStack {
                        Text("\(idx + 1)").font(.caption.monospaced()).foregroundStyle(.secondary)
                        Text(item.name)
                        Spacer()
                        Text("\(item.count)回").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    if idx < top.count - 1 { Divider() }
                }
            }
        } title: "よく訪れる路線"
    }

    private var topStationsSection: some View {
        let top = Statistics.topStations(sightings: sightings)
        return statCard {
            if top.isEmpty {
                Text("まだ記録がありません").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(Array(top.enumerated()), id: \.offset) { idx, item in
                    HStack {
                        Text("\(idx + 1)").font(.caption.monospaced()).foregroundStyle(.secondary)
                        Text(item.name)
                        Spacer()
                        Text("\(item.count)回").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    if idx < top.count - 1 { Divider() }
                }
            }
        } title: "よく行く駅"
    }

    private var monthlyChartSection: some View {
        let series = Statistics.monthlySightings(sightings: sightings)
        let maxCount = max(series.map(\.count).max() ?? 0, 1)
        return statCard {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(series.enumerated()), id: \.offset) { _, point in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(.orange.gradient)
                            .frame(width: 18, height: max(4, CGFloat(point.count) / CGFloat(maxCount) * 90))
                        Text(point.month, format: .dateTime.month(.narrow))
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(point.month, format: .dateTime.year().month()))
                    .accessibilityValue("\(point.count)件")
                }
            }
            .frame(maxWidth: .infinity)
        } title: "直近12ヶ月の遭遇"
    }

    private var lastRunSection: some View {
        let count = Statistics.lastRunCount(sightings: sightings)
        return statCard {
            HStack {
                Label("ラストラン記録", systemImage: "star.fill")
                    .foregroundStyle(.red)
                Spacer()
                Text("\(count) 件").font(.headline.monospaced())
            }
            Text("引退するその瞬間を、あなたは見届けた。")
                .font(.caption)
                .foregroundStyle(.secondary)
        } title: "見送った車両たち"
    }

    // MARK: - スタイル

    @ViewBuilder
    private func statCard<Content: View>(@ViewBuilder content: () -> Content, title: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(.orange)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatsView()
        .modelContainer(PreviewData.container)
}
