import SwiftUI
import SwiftData

/// 図鑑タブ: 国鉄レトロ・上質デザイン。形式ごとの編成コレクション率＋検索・フィルタ。
struct CollectionView: View {
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]

    @State private var query = ""
    @State private var operatorFilter: String = "すべて"
    @State private var showRetiringOnly = false
    @State private var showUncollectedOnly = false

    private let columns = [GridItem(.adaptive(minimum: 168), spacing: 14)]

    private var operators: [String] {
        ["すべて"] + Array(Set(classes.map(\.operatorName))).sorted()
    }

    private var totalRatio: Double {
        let withForms = classes.filter { $0.totalCount > 0 }
        guard !withForms.isEmpty else { return 0 }
        return withForms.map(\.collectionRatio).reduce(0,+) / Double(withForms.count)
    }

    private var filtered: [VehicleClass] {
        classes.filter { vc in
            if !query.isEmpty,
               !vc.name.localizedCaseInsensitiveContains(query),
               !vc.operatorName.localizedCaseInsensitiveContains(query) { return false }
            if operatorFilter != "すべて" && vc.operatorName != operatorFilter { return false }
            if showRetiringOnly && !vc.isRetiring { return false }
            if showUncollectedOnly && vc.collectedCount == vc.totalCount { return false }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NavyBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        MakuHeader(title: "鉄 道 図 鑑",
                                   trailing: "\(Int(totalRatio*100))%")
                            .padding(.top, 8)

                        TodaySuggestionsStrip()

                        filterChips

                        if filtered.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(filtered) { vc in
                                    NavigationLink(value: vc) {
                                        ClassCard(vehicleClass: vc)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(Theme.screenPadding)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.Palette.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { AddVehicleClassView() } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Palette.cream)
                    }
                }
            }
            .searchableNavy(text: $query)
            .navigationDestination(for: VehicleClass.self) { ClassDetailView(vehicleClass: $0) }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(operators, id: \.self) { op in
                        Button(op) { operatorFilter = op }
                    }
                } label: {
                    chip(operatorFilter, system: "building.2", active: operatorFilter != "すべて")
                }
                Button { showRetiringOnly.toggle() } label: {
                    chip("廃車進行中", system: "exclamationmark.triangle", active: showRetiringOnly)
                }
                Button { showUncollectedOnly.toggle() } label: {
                    chip("未コンプ", system: "circle.dotted", active: showUncollectedOnly)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func chip(_ label: String, system: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: system)
            Text(label).font(.system(size: 14, weight: .bold))
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(
            Capsule().fill(active ? Theme.Palette.red : Theme.Palette.paper.opacity(0.12))
        )
        .foregroundStyle(active ? Theme.Palette.paper : Theme.Palette.cream)
        .overlay(Capsule().stroke(Theme.Palette.cream.opacity(0.2), lineWidth: active ? 0 : 1))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Palette.creamSub)
            Text("該当する形式がありません")
                .font(Theme.Font.headline(18))
                .foregroundStyle(Theme.Palette.cream)
            Text("載っていない車両は、＋から自分で追加できます。")
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.Palette.creamSub)
                .multilineTextAlignment(.center)
            NavigationLink { AddVehicleClassView() } label: {
                Text("形式を追加")
                    .font(.system(size: 15, weight: .bold))
                    .padding(.horizontal, 22).padding(.vertical, 12)
                    .background(Capsule().fill(Theme.Palette.red))
                    .foregroundStyle(Theme.Palette.paper)
            }
        }
        .padding(.top, 60)
    }
}

private struct ClassCard: View {
    let vehicleClass: VehicleClass

    /// 形式の管理単位から代表的な編成シルエットを描く
    private var diagramKinds: [CarDiagram.Kind] {
        switch vehicleClass.unitType {
        case .locomotive: return [.loco]
        case .railcar:    return [.cab, .plain, .cab]
        case .formation:  return [.cab, .motor, .plain, .motor, .cab]
        }
    }

    var body: some View {
        PaperCard(accent: true, aged: vehicleClass.isRetiring, interactive: true) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(vehicleClass.name)
                        .font(Theme.Font.headline(20))
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(1)
                    Spacer()
                    if vehicleClass.isComplete {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.Palette.goldDeep)
                    } else if vehicleClass.isRetiring {
                        InkBadge(text: "廃車", filled: false)
                    }
                }
                Text(vehicleClass.operatorName)
                    .font(Theme.Font.body(13))
                    .foregroundStyle(Theme.Palette.inkSub)

                CarDiagram(diagramKinds, stroke: vehicleClass.isRetiring ? Theme.Palette.rail : Theme.Palette.cyan, height: 22)
                    .padding(.vertical, 4)

                RailGauge(ratio: vehicleClass.collectionRatio, complete: vehicleClass.isComplete)
                    .padding(.top, 2)

                HStack {
                    Text("\(vehicleClass.collectedCount) / \(vehicleClass.totalCount) \(vehicleClass.unitType.counter)")
                        .font(Theme.Font.mono(13))
                        .foregroundStyle(Theme.Palette.inkSub)
                    Spacer()
                    Text("\(Int(vehicleClass.collectionRatio * 100))%")
                        .font(Theme.Font.mono(14))
                        .foregroundStyle(vehicleClass.isComplete ? Theme.Palette.goldDeep : Theme.Palette.red)
                }
            }
        }
    }
}

/// 形式詳細
struct ClassDetailView: View {
    let vehicleClass: VehicleClass
    @State private var query = ""

    private var formations: [Formation] {
        let s = (vehicleClass.formations ?? []).sorted { $0.code < $1.code }
        return query.isEmpty ? s : s.filter { $0.code.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ZStack {
            NavyBackground()
            ScrollView {
                VStack(spacing: 14) {
                    PaperCard(accent: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label(vehicleClass.operatorName, systemImage: "building.2")
                                    .font(Theme.Font.body(14))
                                    .foregroundStyle(Theme.Palette.inkSub)
                                Spacer()
                                if vehicleClass.isComplete {
                                    Label("コンプリート", systemImage: "checkmark.seal.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Theme.Palette.goldDeep)
                                }
                            }
                            if !vehicleClass.lineNames.isEmpty {
                                Text(vehicleClass.lineNames.joined(separator: " / "))
                                    .font(Theme.Font.body(13))
                                    .foregroundStyle(Theme.Palette.inkSub)
                            }
                            RailGauge(ratio: vehicleClass.collectionRatio, complete: vehicleClass.isComplete)
                            Text("\(vehicleClass.collectedCount) / \(vehicleClass.totalCount) \(vehicleClass.unitType.counter)")
                                .font(Theme.Font.mono(13))
                                .foregroundStyle(Theme.Palette.inkSub)
                        }
                    }

                    ForEach(formations) { f in
                        NavigationLink(value: f) { FormationRow(formation: f, unit: vehicleClass.unitType) }
                            .buttonStyle(.plain)
                    }

                    NavigationLink { AddFormationView(vehicleClass: vehicleClass) } label: {
                        Label("\(vehicleClass.unitType.unitLabel)を追加", systemImage: "plus.circle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.Palette.cream)
                            .padding(.vertical, 8)
                    }
                }
                .padding(Theme.screenPadding)
            }
        }
        .navigationTitle(vehicleClass.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchableNavy(text: $query)
        .navigationDestination(for: Formation.self) { FormationDetailView(formation: $0) }
    }
}

private struct FormationRow: View {
    let formation: Formation
    let unit: UnitType
    var body: some View {
        PaperCard(accent: formation.isCollected,
                  aged: !formation.isActive,
                  interactive: true) {
            HStack {
                Image(systemName: formation.isCollected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(formation.isCollected ? Theme.Palette.red : Theme.Palette.inkSub)
                VStack(alignment: .leading, spacing: 2) {
                    Text(formation.code).font(Theme.Font.mono(17)).foregroundStyle(Theme.Palette.ink)
                    if let last = formation.lastSeen {
                        Text("最終: \(last, format: .dateTime.year().month().day())")
                            .font(Theme.Font.mono(11)).foregroundStyle(Theme.Palette.inkSub)
                    }
                }
                Spacer()
                if formation.sightingCount > 0 {
                    Text("\(formation.sightingCount)回").font(Theme.Font.mono(13)).foregroundStyle(Theme.Palette.inkSub)
                }
                if !formation.isActive {
                    Image(systemName: "xmark.bin").foregroundStyle(Theme.Palette.red)
                }
            }
        }
    }
}

/// 編成詳細: 遭遇履歴と写真・録音
struct FormationDetailView: View {
    let formation: Formation
    @State private var sharingSighting: Sighting?
    private var sightings: [Sighting] { (formation.sightings ?? []).sorted { $0.date > $1.date } }

    var body: some View {
        ZStack {
            NavyBackground()
            ScrollView {
                VStack(spacing: 14) {
                    PaperCard(accent: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            detailRow("形式", formation.vehicleClass?.name ?? "—")
                            detailRow("編成", formation.code)
                            detailRow("両数", "\(formation.carCount)両")
                            if let f = formation.firstSeen { detailRow("初遭遇", f.formatted(date: .abbreviated, time: .omitted)) }
                            if let l = formation.lastSeen { detailRow("最終遭遇", l.formatted(date: .abbreviated, time: .omitted)) }
                            detailRow("遭遇回数", "\(formation.sightingCount)")
                        }
                    }

                    ForEach(sightings) { s in
                        VStack(spacing: 10) {
                            // ① 硬券（クリーム券）
                            SightingTicketDetail(sighting: s)
                            // ② 添付（写真・録音）はダークガラスで“別物”として下に
                            if !s.photoFilenames.isEmpty || !s.audioFilenames.isEmpty {
                                PaperCard(accent: false) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        if let file = s.photoFilenames.first, let img = PhotoStore.load(file) {
                                            Image(uiImage: img).resizable().scaledToFill()
                                                .frame(height: 160).frame(maxWidth: .infinity)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        ForEach(s.audioFilenames, id: \.self) { AudioPlayerRow(filename: $0) }
                                    }
                                }
                            }
                        }
                        .contextMenu {
                            Button { sharingSighting = s } label: { Label("きっぷを共有", systemImage: "ticket") }
                        }
                    }
                }
                .padding(Theme.screenPadding)
            }
        }
        .navigationTitle(formation.code)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $sharingSighting) { TicketShareSheet(sighting: $0) }
    }

    private func detailRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(Theme.Font.body(14)).foregroundStyle(Theme.Palette.inkSub)
            Spacer()
            Text(v).font(Theme.Font.body(15)).foregroundStyle(Theme.Palette.ink)
        }
    }
}

/// 遭遇1件の硬券（詳細用・大判）。LogViewの小判 SightingCard と同系統だが、
/// 形式・編成番号・列車番号・車番・天気まで券面に同居する。
private struct SightingTicketDetail: View {
    let sighting: Sighting

    var body: some View {
        KikenCard(edge: edgeColor, aged: aged) {
            VStack(alignment: .leading, spacing: 8) {
                // 上段：路線（明朝大）／日付印
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sighting.lineName.isEmpty ? "（路線未設定）" : sighting.lineName)
                            .font(.system(size: 22, weight: .heavy, design: .serif))
                            .foregroundStyle(Theme.Palette.paperInk)
                        Text(operatorLabel)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(Theme.Palette.paperInkSub)
                    }
                    Spacer(minLength: 8)
                    DatingStamp(text: stampText)
                }

                // 形式・編成（券面の主役）
                Text(label)
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.Palette.paperInk)

                // 諸元グリッド（罫線で区切る）
                Rectangle().fill(Color(hex: 0x46341A).opacity(0.35)).frame(height: 1).padding(.top, 2)
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 7) {
                    cell(k: "遭遇駅", v: sighting.stationName.isEmpty ? "—" : sighting.stationName)
                    if !sighting.trainNumber.isEmpty { cell(k: "列車番号", v: sighting.trainNumber) }
                    if !sighting.carNumber.isEmpty   { cell(k: "車 番",    v: sighting.carNumber) }
                    if !sighting.weather.isEmpty     { cell(k: "天 気",    v: sighting.weather) }
                    if !sighting.headmark.isEmpty    { cell(k: "ヘッドマーク", v: sighting.headmark) }
                    if !sighting.livery.isEmpty      { cell(k: "塗 装",    v: sighting.livery) }
                    cell(k: "種 別", v: sighting.isLastRun ? "ラストラン" : sighting.kind.rawValue)
                }
                Rectangle().fill(Color(hex: 0x46341A).opacity(0.35)).frame(height: 1)

                // 下段：様式番号・小書き・通し番号
                HStack(alignment: .center) {
                    Text("様式 (2) 図 — \(formCode)")
                        .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.Palette.paperInkSub)
                    Spacer()
                    TicketMicroprint()
                    Spacer()
                    Text("No. \(serial)")
                        .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.Palette.paperInkSub)
                }
            }
        }
    }

    private func cell(k: String, v: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(k)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(Theme.Palette.paperInkSub)
            Text(v)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.Palette.paperInk)
                .lineLimit(1)
        }
    }

    private var aged: Bool {
        sighting.isLastRun || sighting.formation?.vehicleClass?.isRetiring == true
    }

    private var edgeColor: Color {
        if sighting.isLastRun { return Theme.Palette.red }
        switch sighting.kind {
        case .scheduled:                  return Color(hex: 0x1D4E86)
        case .extra, .charter, .lastRun:  return Theme.Palette.red
        case .deadhead, .test, .delivery: return Color(hex: 0x2C6A3C)
        }
    }

    private var label: String {
        guard let f = sighting.formation else { return "（編成未設定）" }
        return "\(f.vehicleClass?.name ?? "")  \(f.code)"
    }

    private var operatorLabel: String {
        let op = sighting.formation?.vehicleClass?.operatorName ?? ""
        let cat = sighting.formation?.vehicleClass?.category ?? ""
        return [op, cat].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var stampText: String {
        let cal = Calendar(identifier: .gregorian)
        let yy = cal.component(.year, from: sighting.date) % 100
        let mm = cal.component(.month, from: sighting.date)
        let dd = cal.component(.day, from: sighting.date)
        return String(format: "%02d.%2d.%2d", yy, mm, dd)
    }

    private var serial: String {
        let f = DateFormatter(); f.dateFormat = "yyMMdd"
        let suffix = abs((sighting.formation?.code ?? sighting.id.uuidString).hashValue) % 10000
        return "\(f.string(from: sighting.date))-\(String(format: "%04d", suffix))"
    }

    private var formCode: String {
        String(format: "%04d", abs(sighting.id.uuidString.hashValue) % 10000)
    }
}

// MARK: - 紺背景に合う検索バー装飾
private extension View {
    func searchableNavy(text: Binding<String>) -> some View {
        self.searchable(text: text, prompt: "形式名・事業者・編成で検索")
    }
}

#Preview {
    CollectionView().modelContainer(PreviewData.container)
}
