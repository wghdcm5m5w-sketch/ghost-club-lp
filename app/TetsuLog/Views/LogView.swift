import SwiftUI
import SwiftData

enum LogGrouping: String, CaseIterable, Identifiable {
    case year = "年"
    case month = "月"
    case className = "形式"
    case lineName = "路線"
    var id: String { rawValue }
}

enum LogMode: String, CaseIterable, Identifiable {
    case sightings = "遭遇"
    case rides = "乗車"
    var id: String { rawValue }
}

/// 記録タブ: 遭遇記録／乗車記録の一覧・編集・削除。
struct LogView: View {
    @Query(sort: \Sighting.date, order: .reverse) private var sightings: [Sighting]
    @Query(sort: \RideSegment.date, order: .reverse) private var rides: [RideSegment]
    @Environment(RideManager.self) private var rideManager
    @Environment(\.modelContext) private var context
    @AppStorage("tetsulog.logGrouping") private var groupingRaw: String = LogGrouping.year.rawValue
    @State private var mode: LogMode = .sightings
    @State private var showingAdd = false
    @State private var showingStartRide = false
    @State private var showingActiveRide = false
    @State private var editingSighting: Sighting?
    @State private var editingRide: RideSegment?
    @State private var query = ""

    private var grouping: LogGrouping { LogGrouping(rawValue: groupingRaw) ?? .year }

    /// 検索フィルタ済みの遭遇記録（編成・形式・駅・路線・車番・装飾・メモを横断）
    private var filteredSightings: [Sighting] {
        guard !query.isEmpty else { return sightings }
        let q = query
        return sightings.filter { s in
            let hay = [
                s.formation?.code ?? "",
                s.formation?.vehicleClass?.name ?? "",
                s.stationName, s.lineName, s.carNumber,
                s.headmark, s.livery, s.trainNumber, s.note
            ]
            return hay.contains { $0.localizedCaseInsensitiveContains(q) }
        }
    }

    private var filteredRides: [RideSegment] {
        guard !query.isEmpty else { return rides }
        let q = query
        return rides.filter { r in
            [r.fromStation, r.toStation, r.lineName, r.formationCode, r.note]
                .contains { $0.localizedCaseInsensitiveContains(q) }
        }
    }

    private var groups: [(key: String, items: [Sighting])] {
        let cal = Calendar.current
        let source = filteredSightings
        let dict: [String: [Sighting]]
        switch grouping {
        case .year:
            dict = Dictionary(grouping: source) { "\(cal.component(.year, from: $0.date))" }
        case .month:
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy / MM"
            dict = Dictionary(grouping: source) { fmt.string(from: $0.date) }
        case .className:
            dict = Dictionary(grouping: source) { $0.formation?.vehicleClass?.name ?? "（未設定）" }
        case .lineName:
            dict = Dictionary(grouping: source) { $0.lineName.isEmpty ? "（未設定）" : $0.lineName }
        }
        return dict.keys.sorted(by: >).map { (key: $0, items: dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if mode == .sightings {
                    sightingsList
                } else {
                    ridesList
                }
            }
            .navigationTitle("記録")
            .safeAreaInset(edge: .top) {
                VStack(spacing: 8) {
                    if rideManager.isActive { activeRideBanner }
                    Picker("モード", selection: $mode) {
                        ForEach(LogMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding(.bottom, 4)
                .background(.bar)
            }
            .toolbar {
                if mode == .sightings {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Picker("グルーピング", selection: $groupingRaw) {
                                ForEach(LogGrouping.allCases) { Text($0.rawValue).tag($0.rawValue) }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAdd = true
                        } label: { Label("遭遇を記録", systemImage: "tram") }
                        Button {
                            if rideManager.isActive { showingActiveRide = true }
                            else { showingStartRide = true }
                        } label: {
                            Label(rideManager.isActive ? "乗車中の画面" : "乗車を開始",
                                  systemImage: "play.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $query, prompt: "編成・駅・路線・車番・メモで検索")
            .sheet(isPresented: $showingAdd) { AddSightingView() }
            .sheet(item: $editingSighting) { AddSightingView(editing: $0) }
            .sheet(item: $editingRide) { RideEditView(ride: $0) }
            .sheet(isPresented: $showingStartRide) { StartRideView(manager: rideManager) }
            .sheet(isPresented: $showingActiveRide) { ActiveRideView(manager: rideManager) }
        }
    }

    // MARK: - 遭遇リスト

    @ViewBuilder
    private var sightingsList: some View {
        if filteredSightings.isEmpty {
            ContentUnavailableView(
                query.isEmpty ? "まだ記録がありません" : "該当する記録がありません",
                systemImage: "tram",
                description: Text(query.isEmpty ? "右上の＋から、出会った編成を記録しましょう。" : "検索条件を変えてみてください。")
            )
        } else {
            List {
                ForEach(groups, id: \.key) { group in
                    Section("\(group.key) · \(group.items.count)件") {
                        ForEach(group.items) { s in
                            Button { editingSighting = s } label: {
                                SightingRow(sighting: s)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) { delete(s) } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 乗車リスト

    @ViewBuilder
    private var ridesList: some View {
        if filteredRides.isEmpty {
            ContentUnavailableView(
                query.isEmpty ? "乗車記録がありません" : "該当する乗車記録がありません",
                systemImage: "figure.seated.side",
                description: Text(query.isEmpty ? "「乗車を開始」または＋から記録できます。" : "検索条件を変えてみてください。")
            )
        } else {
            List {
                ForEach(filteredRides) { r in
                    Button { editingRide = r } label: {
                        RideRow(ride: r)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) { delete(r) } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var activeRideBanner: some View {
        Button { showingActiveRide = true } label: {
            HStack {
                Image(systemName: "tram.fill")
                Text("乗車中: \(rideManager.className) \(rideManager.formationCode)")
                    .font(.subheadline.weight(.semibold)).lineLimit(1)
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

    private func delete(_ s: Sighting) {
        for file in s.photoFilenames { PhotoStore.delete(file) }
        for file in s.audioFilenames { AudioStore.delete(file) }
        context.delete(s); try? context.save(); Haptics.tick()
    }
    private func delete(_ r: RideSegment) {
        context.delete(r); try? context.save(); Haptics.tick()
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
                Text(formationLabel).font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text("\(sighting.lineName) · \(sighting.stationName)")
                        .font(.caption).foregroundStyle(.secondary)
                    if !sighting.headmark.isEmpty { miniTag(sighting.headmark, color: .orange) }
                    if !sighting.livery.isEmpty { miniTag(sighting.livery, color: .purple) }
                    if !sighting.audioFilenames.isEmpty {
                        Image(systemName: "waveform")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(sighting.date, format: .dateTime.month().day())
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
                if sighting.isLastRun {
                    Text("ラストラン").font(.caption2.bold()).foregroundStyle(.red)
                } else if sighting.kind != .scheduled {
                    Text(sighting.kind.rawValue).font(.caption2.bold()).foregroundStyle(.blue)
                }
            }
        }
    }
    private func miniTag(_ text: String, color: Color) -> some View {
        Text(text).font(.caption2)
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(color.opacity(0.18), in: Capsule()).foregroundStyle(color)
    }
    private var formationLabel: String {
        guard let f = sighting.formation else { return "（編成未設定）" }
        return "\(f.vehicleClass?.name ?? "") \(f.code)"
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

private struct RideRow: View {
    let ride: RideSegment
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.seated.side").foregroundStyle(.green).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(ride.fromStation) → \(ride.toStation)")
                    .font(.subheadline.weight(.semibold))
                Text(ride.lineName.isEmpty ? "—" : ride.lineName)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(ride.date, format: .dateTime.year().month().day())
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
                if ride.distanceKm > 0 {
                    Text(String(format: "%.1f km", ride.distanceKm))
                        .font(.caption2.monospaced()).foregroundStyle(.green)
                }
            }
        }
    }
}

#Preview {
    LogView()
        .modelContainer(PreviewData.container)
        .environment(RideManager())
}
