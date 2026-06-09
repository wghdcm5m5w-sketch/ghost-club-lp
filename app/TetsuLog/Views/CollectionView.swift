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
                        PaperCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(s.date, format: .dateTime.year().month().day())
                                        .font(Theme.Font.mono(13)).foregroundStyle(Theme.Palette.inkSub)
                                    Spacer()
                                    if s.isLastRun { InkBadge(text: "ラストラン") }
                                }
                                if let file = s.photoFilenames.first, let img = PhotoStore.load(file) {
                                    Image(uiImage: img).resizable().scaledToFill()
                                        .frame(height: 150).frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                Text("\(s.lineName) · \(s.stationName)")
                                    .font(Theme.Font.body(15)).foregroundStyle(Theme.Palette.ink)
                                if !s.carNumber.isEmpty {
                                    Text(s.carNumber).font(Theme.Font.mono(12)).foregroundStyle(Theme.Palette.inkSub)
                                }
                                if !s.headmark.isEmpty || !s.livery.isEmpty {
                                    HStack(spacing: 6) {
                                        if !s.headmark.isEmpty { tag(s.headmark) }
                                        if !s.livery.isEmpty { tag(s.livery) }
                                    }
                                }
                                ForEach(s.audioFilenames, id: \.self) { AudioPlayerRow(filename: $0) }
                            }
                        }
                    }
                }
                .padding(Theme.screenPadding)
            }
        }
        .navigationTitle(formation.code)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func detailRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(Theme.Font.body(14)).foregroundStyle(Theme.Palette.inkSub)
            Spacer()
            Text(v).font(Theme.Font.body(15)).foregroundStyle(Theme.Palette.ink)
        }
    }
    private func tag(_ t: String) -> some View {
        Text(t).font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(Theme.Palette.navy.opacity(0.1)))
            .foregroundStyle(Theme.Palette.navy)
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
