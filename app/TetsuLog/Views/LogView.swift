import SwiftUI
import SwiftData

enum LogGrouping: String, CaseIterable, Identifiable {
    case year = "年"
    case month = "月"
    case className = "形式"
    case lineName = "路線"
    var id: String { rawValue }
}

/// 記録タブ: 遭遇記録を選択した軸でグルーピングするタイムライン。
struct LogView: View {
    @Query(sort: \Sighting.date, order: .reverse) private var sightings: [Sighting]
    @Environment(RideManager.self) private var rideManager
    @AppStorage("tetsulog.logGrouping") private var groupingRaw: String = LogGrouping.year.rawValue
    @State private var showingAdd = false
    @State private var showingStartRide = false
    @State private var showingActiveRide = false

    private var grouping: LogGrouping {
        get { LogGrouping(rawValue: groupingRaw) ?? .year }
    }

    private var groups: [(key: String, items: [Sighting])] {
        let cal = Calendar.current
        let dict: [String: [Sighting]]
        switch grouping {
        case .year:
            dict = Dictionary(grouping: sightings) { "\(cal.component(.year, from: $0.date))" }
        case .month:
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy / MM"
            dict = Dictionary(grouping: sightings) { fmt.string(from: $0.date) }
        case .className:
            dict = Dictionary(grouping: sightings) { $0.formation?.vehicleClass?.name ?? "（未設定）" }
        case .lineName:
            dict = Dictionary(grouping: sightings) { $0.lineName.isEmpty ? "（未設定）" : $0.lineName }
        }
        return dict.keys.sorted(by: >).map { (key: $0, items: dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sightings.isEmpty {
                    ContentUnavailableView(
                        "まだ記録がありません",
                        systemImage: "tram",
                        description: Text("右上の＋から、出会った編成を記録しましょう。")
                    )
                } else {
                    List {
                        ForEach(groups, id: \.key) { group in
                            Section("\(group.key) · \(group.items.count)件") {
                                ForEach(group.items) { s in
                                    SightingRow(sighting: s)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("記録")
            .safeAreaInset(edge: .top) {
                if rideManager.isActive {
                    activeRideBanner
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("グルーピング", selection: $groupingRaw) {
                            ForEach(LogGrouping.allCases) { g in
                                Text(g.rawValue).tag(g.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAdd = true
                        } label: {
                            Label("遭遇を記録", systemImage: "tram")
                        }
                        Button {
                            if rideManager.isActive {
                                showingActiveRide = true
                            } else {
                                showingStartRide = true
                            }
                        } label: {
                            Label(rideManager.isActive ? "乗車中の画面" : "乗車を開始",
                                  systemImage: "play.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSightingView()
            }
            .sheet(isPresented: $showingStartRide) {
                StartRideView(manager: rideManager)
            }
            .sheet(isPresented: $showingActiveRide) {
                ActiveRideView(manager: rideManager)
            }
        }
    }

    private var activeRideBanner: some View {
        Button {
            showingActiveRide = true
        } label: {
            HStack {
                Image(systemName: "tram.fill")
                Text("乗車中: \(rideManager.className) \(rideManager.formationCode)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.orange)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

private struct SightingRow: View {
    let sighting: Sighting

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(formationLabel)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text("\(sighting.lineName) · \(sighting.stationName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !sighting.headmark.isEmpty {
                        miniTag(sighting.headmark, color: .orange)
                    }
                    if !sighting.livery.isEmpty {
                        miniTag(sighting.livery, color: .purple)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(sighting.date, format: .dateTime.month().day())
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                if sighting.isLastRun {
                    Text("ラストラン")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                } else if sighting.kind != .scheduled {
                    Text(sighting.kind.rawValue)
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private func miniTag(_ text: String, color: Color) -> some View {
        Text(text).font(.caption2)
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var formationLabel: String {
        guard let f = sighting.formation else { return "（編成未設定）" }
        let cls = f.vehicleClass?.name ?? ""
        return "\(cls) \(f.code)"
    }

    private var iconName: String {
        switch sighting.kind {
        case .scheduled: return "tram.fill"
        case .extra: return "sparkles"
        case .deadhead: return "arrow.left.arrow.right"
        case .test: return "wrench.and.screwdriver"
        case .delivery: return "shippingbox"
        case .charter: return "person.3.fill"
        case .lastRun: return "star.fill"
        }
    }

    private var iconColor: Color {
        switch sighting.kind {
        case .scheduled: return .orange
        case .lastRun: return .red
        case .extra: return .purple
        default: return .blue
        }
    }
}

#Preview {
    LogView()
        .modelContainer(PreviewData.container)
        .environment(RideManager())
}
