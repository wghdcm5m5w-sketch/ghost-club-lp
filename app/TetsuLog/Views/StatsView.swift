import SwiftUI
import SwiftData

/// 統計タブ: 国鉄レトロ・上質デザイン。
struct StatsView: View {
    @Query private var sightings: [Sighting]
    @Query private var rides: [RideSegment]
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]

    private var overview: Statistics.Overview { Statistics.overview(sightings: sightings, rides: rides) }

    private var collectionRatio: Double {
        let withForms = classes.filter { $0.totalCount > 0 }
        guard !withForms.isEmpty else { return 0 }
        return withForms.map(\.collectionRatio).reduce(0, +) / Double(withForms.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NavyBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        MakuHeader(title: "成 績", kicker: "DASHBOARD").padding(.top, 8)
                        gaugeCard
                        overviewCard
                        completionCard
                        rankCard("よく出会う形式", Statistics.topClasses(sightings: sightings))
                        rankCard("よく訪れる路線", Statistics.topLines(sightings: sightings))
                        rankCard("よく行く駅", Statistics.topStations(sightings: sightings))
                        monthlyCard
                        lastRunCard
                    }
                    .padding(Theme.screenPadding)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.Palette.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var gaugeCard: some View {
        PaperCard(accent: false) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottom) {
                    GaugeArc(ratio: collectionRatio)
                        .frame(width: 188, height: 100)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(Int(collectionRatio * 100))")
                            .font(.system(size: 40, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.Palette.cyan)
                        Text("%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.Palette.cyanDim)
                    }
                    .padding(.bottom, 6)
                }
                Text("TOTAL 収集率")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Theme.Palette.inkSub)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private var overviewCard: some View {
        let o = overview
        return PaperCard(accent: false) {
            HStack(alignment: .top) {
                tile("\(o.totalSightings)", "遭遇")
                divider; tile("\(o.collectedFormations)", "編成")
                divider; tile(String(format:"%.0f",o.totalRideKm), "km")
                divider; tile(String(format:"%.0f",o.totalRideHours), "時間")
            }
        }
    }

    private var completionCard: some View {
        let complete = classes.filter { $0.isComplete && $0.totalCount > 0 }.count
        let partial = classes.filter { !$0.isComplete && $0.collectedCount > 0 }.count
        return PaperCard {
            VStack(spacing: 12) {
                HStack {
                    Label("コンプリート", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.Palette.goldDeep)
                        .font(Theme.Font.body(15))
                    Spacer()
                    Text("\(complete) 形式").font(Theme.Font.mono(18)).foregroundStyle(Theme.Palette.ink)
                }
                Rectangle().fill(Theme.Palette.paperEdge).frame(height:1)
                HStack {
                    Label("収集中", systemImage: "circle.dotted").foregroundStyle(Theme.Palette.red)
                        .font(Theme.Font.body(15))
                    Spacer()
                    Text("\(partial) 形式").font(Theme.Font.mono(18)).foregroundStyle(Theme.Palette.ink)
                }
            }
        }
    }

    private func rankCard(_ title: String, _ items: [(name:String,count:Int)]) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(Theme.Font.headline(16)).foregroundStyle(Theme.Palette.ink)
                if items.isEmpty {
                    Text("まだ記録がありません").font(Theme.Font.body(13)).foregroundStyle(Theme.Palette.inkSub)
                } else {
                    ForEach(Array(items.enumerated()), id: \.offset) { i, it in
                        HStack {
                            Text("\(i+1)").font(Theme.Font.mono(13)).foregroundStyle(Theme.Palette.red).frame(width: 22)
                            Text(it.name).font(Theme.Font.body(15)).foregroundStyle(Theme.Palette.ink)
                            Spacer()
                            Text("\(it.count)回").font(Theme.Font.mono(13)).foregroundStyle(Theme.Palette.inkSub)
                        }
                    }
                }
            }
        }
    }

    private var monthlyCard: some View {
        let series = Statistics.monthlySightings(sightings: sightings)
        let maxC = max(series.map(\.count).max() ?? 0, 1)
        return PaperCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("直近12ヶ月の遭遇").font(Theme.Font.headline(16)).foregroundStyle(Theme.Palette.ink)
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(series.enumerated()), id: \.offset) { _, p in
                        VStack(spacing: 4) {
                            Rectangle().fill(Theme.Palette.red)
                                .frame(width: 16, height: max(4, CGFloat(p.count)/CGFloat(maxC)*90))
                            Text(p.month, format: .dateTime.month(.narrow))
                                .font(.system(size:10,design:.monospaced)).foregroundStyle(Theme.Palette.inkSub)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(p.month, format: .dateTime.year().month()))
                        .accessibilityValue("\(p.count)件")
                    }
                }.frame(maxWidth: .infinity)
            }
        }
    }

    private var lastRunCard: some View {
        let c = Statistics.lastRunCount(sightings: sightings)
        return PaperCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("見送った車両たち", systemImage: "star.fill").foregroundStyle(Theme.Palette.red)
                        .font(Theme.Font.headline(16))
                    Spacer()
                    Text("\(c) 件").font(Theme.Font.mono(18)).foregroundStyle(Theme.Palette.ink)
                }
                Text("引退するその瞬間を、あなたは見届けた。")
                    .font(Theme.Font.body(13)).foregroundStyle(Theme.Palette.inkSub)
            }
        }
    }

    private func tile(_ v: String, _ l: String) -> some View {
        VStack(spacing: 4) {
            Text(v).font(.system(size: 28, weight: .heavy, design: .serif).monospacedDigit())
                .foregroundStyle(Theme.Palette.red)
            Text(l).font(Theme.Font.body(12)).foregroundStyle(Theme.Palette.inkSub)
        }.frame(maxWidth: .infinity)
    }
    private var divider: some View { Rectangle().fill(Theme.Palette.paperEdge).frame(width:1, height:44) }
}

#Preview { StatsView().modelContainer(PreviewData.container) }
