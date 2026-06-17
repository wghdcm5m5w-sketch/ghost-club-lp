import SwiftUI
import SwiftData

enum LogGrouping: String, CaseIterable, Identifiable {
    case year = "年"; case month = "月"; case className = "形式"; case lineName = "路線"
    var id: String { rawValue }
}
enum LogMode: String, CaseIterable, Identifiable {
    case sightings = "遭遇"; case rides = "乗車"
    var id: String { rawValue }
}

/// 記録タブ: 国鉄レトロ・上質デザイン。
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
    @State private var sharingSighting: Sighting?
    @State private var query = ""

    private var grouping: LogGrouping { LogGrouping(rawValue: groupingRaw) ?? .year }

    private var filteredSightings: [Sighting] {
        guard !query.isEmpty else { return sightings }
        return sightings.filter { s in
            [s.formation?.code ?? "", s.formation?.vehicleClass?.name ?? "",
             s.stationName, s.lineName, s.carNumber, s.headmark, s.livery, s.trainNumber, s.note]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    private var filteredRides: [RideSegment] {
        guard !query.isEmpty else { return rides }
        return rides.filter { r in
            [r.fromStation, r.toStation, r.lineName, r.formationCode, r.note]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    private var groups: [(key: String, items: [Sighting])] {
        let cal = Calendar.current; let src = filteredSightings
        let dict: [String:[Sighting]]
        switch grouping {
        case .year: dict = Dictionary(grouping: src){ "\(cal.component(.year,from:$0.date))" }
        case .month:
            let f=DateFormatter(); f.dateFormat="yyyy / MM"
            dict = Dictionary(grouping: src){ f.string(from:$0.date) }
        case .className: dict = Dictionary(grouping: src){ $0.formation?.vehicleClass?.name ?? "（未設定）" }
        case .lineName: dict = Dictionary(grouping: src){ $0.lineName.isEmpty ? "（未設定）" : $0.lineName }
        }
        return dict.keys.sorted(by:>).map{ ($0, dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NavyBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        if rideManager.isActive { activeRideBanner }
                        modePicker
                        if mode == .sightings { sightingsContent } else { ridesContent }
                    }
                    .padding(Theme.screenPadding)
                }
            }
            .navigationTitle("記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.Palette.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if mode == .sightings {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Picker("グルーピング", selection: $groupingRaw) {
                                ForEach(LogGrouping.allCases){ Text($0.rawValue).tag($0.rawValue) }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle").foregroundStyle(Theme.Palette.cream)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showingAdd = true } label: { Label("遭遇を記録", systemImage: "tram") }
                        Button {
                            if rideManager.isActive { showingActiveRide = true } else { showingStartRide = true }
                        } label: { Label(rideManager.isActive ? "乗車中の画面" : "乗車を開始", systemImage: "play.circle") }
                    } label: { Image(systemName: "plus").foregroundStyle(Theme.Palette.cream) }
                }
            }
            .searchable(text: $query, prompt: "編成・駅・路線・車番・メモで検索")
            .sheet(isPresented: $showingAdd){ AddSightingView() }
            .sheet(item: $editingSighting){ AddSightingView(editing: $0) }
            .sheet(item: $sharingSighting){ TicketShareSheet(sighting: $0) }
            .sheet(item: $editingRide){ RideEditView(ride: $0) }
            .sheet(isPresented: $showingStartRide){ StartRideView(manager: rideManager) }
            .sheet(isPresented: $showingActiveRide){ ActiveRideView(manager: rideManager) }
        }
    }

    private var modePicker: some View {
        Picker("モード", selection: $mode) {
            ForEach(LogMode.allCases){ Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder private var sightingsContent: some View {
        if filteredSightings.isEmpty {
            emptyState(icon: "tram",
                       title: query.isEmpty ? "まだ記録がありません" : "該当する記録がありません",
                       msg: query.isEmpty ? "右上の＋から、出会った編成を記録しましょう。" : "検索条件を変えてみてください。")
        } else {
            ForEach(groups, id: \.key) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(group.key) · \(group.items.count)件")
                        .font(Theme.Font.mono(13)).foregroundStyle(Theme.Palette.creamSub)
                        .padding(.leading, 4).padding(.top, 6)
                    ForEach(group.items) { s in
                        Button { editingSighting = s } label: { SightingCard(sighting: s) }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button { sharingSighting = s } label: { Label("きっぷを共有", systemImage: "ticket") }
                                Button(role: .destructive){ delete(s) } label: { Label("削除", systemImage:"trash") }
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder private var ridesContent: some View {
        if filteredRides.isEmpty {
            emptyState(icon: "figure.seated.side",
                       title: query.isEmpty ? "乗車記録がありません" : "該当する乗車記録がありません",
                       msg: query.isEmpty ? "「乗車を開始」または＋から記録できます。" : "検索条件を変えてみてください。")
        } else {
            ForEach(filteredRides) { r in
                Button { editingRide = r } label: { RideCard(ride: r) }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive){ delete(r) } label: { Label("削除", systemImage:"trash") }
                    }
            }
        }
    }

    private var activeRideBanner: some View {
        Button { showingActiveRide = true } label: {
            HStack {
                Image(systemName: "tram.fill")
                Text("乗車中: \(rideManager.className) \(rideManager.formationCode)")
                    .font(.system(size:15,weight:.bold)).lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal,16).padding(.vertical,12)
            .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.Palette.red))
            .foregroundStyle(Theme.Palette.paper)
        }
        .buttonStyle(.plain)
    }

    private func emptyState(icon: String, title: String, msg: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size:44)).foregroundStyle(Theme.Palette.creamSub)
            Text(title).font(Theme.Font.headline(18)).foregroundStyle(Theme.Palette.cream)
            Text(msg).font(Theme.Font.body(14)).foregroundStyle(Theme.Palette.creamSub).multilineTextAlignment(.center)
        }.padding(.top, 80)
    }

    private func delete(_ s: Sighting){
        for f in s.photoFilenames { PhotoStore.delete(f) }
        for f in s.audioFilenames { AudioStore.delete(f) }
        context.delete(s); try? context.save(); Haptics.tick()
    }
    private func delete(_ r: RideSegment){ context.delete(r); try? context.save(); Haptics.tick() }
}

/// 遭遇1件を「硬券」に。種別で券種色（赤＝特急/臨時、青＝定期、緑＝回送/試運転等）。
private struct SightingCard: View {
    let sighting: Sighting

    var body: some View {
        KikenCard(edge: edgeColor, aged: aged) {
            VStack(alignment: .leading, spacing: 5) {
                // 上段：路線（明朝大）＋ 事業者・形式の小書き／右上に日付印
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(sighting.lineName.isEmpty ? "（路線未設定）" : sighting.lineName)
                            .font(.system(size: 19, weight: .heavy, design: .serif))
                            .foregroundStyle(Theme.Palette.paperInk)
                            .lineLimit(1)
                        Text(operatorLabel)
                            .font(.system(size: 9.5, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(Theme.Palette.paperInkSub)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    DatingStamp(text: stampText)
                }

                // 形式・編成番号（モノスペース＝券面の打刻風）
                Text(label)
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.Palette.paperInk)
                    .lineLimit(1)

                // 下段：駅名＋アクセサリ
                HStack(spacing: 6) {
                    Text(sighting.stationName.isEmpty ? "—" : sighting.stationName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Palette.paperInk)
                    if !sighting.headmark.isEmpty { microTag(sighting.headmark) }
                    if !sighting.livery.isEmpty { microTag(sighting.livery) }
                    Spacer()
                    if !sighting.audioFilenames.isEmpty {
                        Image(systemName: "waveform")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.Palette.red)
                    }
                    if sighting.isLastRun {
                        Text("ラストラン")
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.Palette.red))
                    } else if sighting.kind != .scheduled {
                        Text(sighting.kind.rawValue)
                            .font(.system(size: 9.5, weight: .heavy))
                            .foregroundStyle(Theme.Palette.red)
                            .padding(.horizontal, 5).padding(.vertical, 1.5)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.Palette.red, lineWidth: 1))
                    }
                }

                // 小書き＋通し番号
                HStack {
                    TicketMicroprint()
                    Spacer()
                    Text("No. \(serial)")
                        .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.Palette.paperInkSub)
                }
                .padding(.top, 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(a11yLabel))
    }

    /// VoiceOver 用の1行サマリ
    private var a11yLabel: String {
        var parts: [String] = []
        parts.append(sighting.lineName.isEmpty ? "路線未設定" : sighting.lineName)
        parts.append(label)
        if !sighting.stationName.isEmpty { parts.append("\(sighting.stationName)にて") }
        parts.append(stampText)
        if sighting.isLastRun { parts.append("ラストラン") }
        else if sighting.kind != .scheduled { parts.append(sighting.kind.rawValue) }
        return parts.joined(separator: "、")
    }

    private func microTag(_ t: String) -> some View {
        Text(t)
            .font(.system(size: 9.5, weight: .bold))
            .foregroundStyle(Color(hex: 0x1D4E86))
            .padding(.horizontal, 5).padding(.vertical, 1)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: 0x1D4E86).opacity(0.5), lineWidth: 0.8))
    }

    private var aged: Bool {
        sighting.isLastRun || sighting.formation?.vehicleClass?.isRetiring == true
    }

    /// 券種色（左帯）。赤＝特急/臨時/ラストラン、青＝定期、緑＝回送/試運転等。
    private var edgeColor: Color {
        if sighting.isLastRun { return Theme.Palette.red }
        switch sighting.kind {
        case .scheduled:                       return Color(hex: 0x1D4E86) // 青＝普通
        case .extra, .charter, .lastRun:       return Theme.Palette.red    // 赤＝臨時/団体
        case .deadhead, .test, .delivery:      return Color(hex: 0x2C6A3C) // 緑＝業務列車
        }
    }

    private var label: String {
        guard let f = sighting.formation else { return "（編成未設定）" }
        let cls = f.vehicleClass?.name ?? ""
        return cls.isEmpty ? f.code : "\(cls)  \(f.code)"
    }

    private var operatorLabel: String {
        let op = sighting.formation?.vehicleClass?.operatorName ?? ""
        let cat = sighting.formation?.vehicleClass?.category ?? ""
        let parts = [op, cat].filter { !$0.isEmpty }
        return parts.isEmpty ? "TETSULOG" : parts.joined(separator: " · ")
    }

    /// ダッチング日付印（昭和書式 26.-6.13 のように年・月・日を空白詰めで）
    private var stampText: String {
        let cal = Calendar(identifier: .gregorian)
        let yy = cal.component(.year, from: sighting.date) % 100
        let mm = cal.component(.month, from: sighting.date)
        let dd = cal.component(.day, from: sighting.date)
        return String(format: "%02d.%2d.%2d", yy, mm, dd)
    }

    /// 券面の通し番号（演出）
    private var serial: String {
        let f = DateFormatter(); f.dateFormat = "yyMMdd"
        let suffix = abs((sighting.formation?.code ?? sighting.id.uuidString).hashValue) % 10000
        return "\(f.string(from: sighting.date))-\(String(format: "%04d", suffix))"
    }
}

private struct RideCard: View {
    let ride: RideSegment
    var body: some View {
        PaperCard(accent: true, interactive: true) {
            HStack(spacing: 12) {
                Image(systemName: "figure.seated.side").foregroundStyle(Theme.Palette.cyan).frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(ride.fromStation) → \(ride.toStation)").font(Theme.Font.headline(17)).foregroundStyle(Theme.Palette.ink)
                    Text(ride.lineName.isEmpty ? "—" : ride.lineName).font(Theme.Font.body(13)).foregroundStyle(Theme.Palette.inkSub)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(ride.date, format: .dateTime.year().month().day()).font(Theme.Font.mono(12)).foregroundStyle(Theme.Palette.inkSub)
                    if ride.distanceKm > 0 {
                        Text(String(format:"%.1f km",ride.distanceKm)).font(Theme.Font.mono(12)).foregroundStyle(Theme.Palette.red)
                    }
                }
            }
        }
    }
}

#Preview {
    LogView().modelContainer(PreviewData.container)
        .environment(RideManager())
        .environment(PurchaseManager())
}
