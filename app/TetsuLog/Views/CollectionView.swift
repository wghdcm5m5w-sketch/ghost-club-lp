import SwiftUI
import SwiftData

/// 図鑑タブ: 形式ごとの編成コレクション率＋検索・フィルタ。
struct CollectionView: View {
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]

    @State private var query = ""
    @State private var operatorFilter: String = "すべて"
    @State private var showRetiringOnly = false
    @State private var showUncollectedOnly = false

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    private var operators: [String] {
        ["すべて"] + Array(Set(classes.map(\.operatorName))).sorted()
    }

    private var filtered: [VehicleClass] {
        classes.filter { vc in
            if !query.isEmpty,
               !vc.name.localizedCaseInsensitiveContains(query),
               !vc.operatorName.localizedCaseInsensitiveContains(query) {
                return false
            }
            if operatorFilter != "すべて" && vc.operatorName != operatorFilter { return false }
            if showRetiringOnly && !vc.isRetiring { return false }
            if showUncollectedOnly && vc.collectedCount == vc.totalCount { return false }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                filterChips
                if filtered.isEmpty {
                    ContentUnavailableView {
                        Label("該当する形式がありません", systemImage: "magnifyingglass")
                    } description: {
                        Text("載っていない車両は、右上の＋から自分で追加できます。")
                    } actions: {
                        NavigationLink {
                            AddVehicleClassView()
                        } label: {
                            Text("形式を追加")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filtered) { vc in
                            NavigationLink(value: vc) {
                                ClassCard(vehicleClass: vc)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("図鑑")
            .searchable(text: $query, prompt: "形式名・事業者で検索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddVehicleClassView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: VehicleClass.self) { vc in
                ClassDetailView(vehicleClass: vc)
            }
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
                    chip(label: operatorFilter, system: "building.2", active: operatorFilter != "すべて")
                }
                Button { showRetiringOnly.toggle() } label: {
                    chip(label: "廃車進行中", system: "exclamationmark.triangle", active: showRetiringOnly)
                }
                Button { showUncollectedOnly.toggle() } label: {
                    chip(label: "未コンプ", system: "circle.dotted", active: showUncollectedOnly)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
    }

    private func chip(label: String, system: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: system)
            Text(label).font(.caption.bold())
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(active ? .orange.opacity(0.18) : Color(.tertiarySystemFill),
                    in: Capsule())
        .foregroundStyle(active ? .orange : Color.primary)
    }
}

private struct ClassCard: View {
    let vehicleClass: VehicleClass

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(vehicleClass.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if vehicleClass.isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("コンプリート")
                } else if vehicleClass.isRetiring {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
            Text(vehicleClass.operatorName)
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: vehicleClass.collectionRatio)
                .tint(vehicleClass.isComplete ? .yellow : .orange)

            HStack {
                Text("\(vehicleClass.collectedCount) / \(vehicleClass.totalCount) \(vehicleClass.unitType.counter)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(vehicleClass.collectionRatio * 100))%")
                    .font(.caption.monospaced().bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// 形式詳細: 編成一覧 + 「最後に出会った日」など
struct ClassDetailView: View {
    let vehicleClass: VehicleClass
    @State private var query = ""

    private var formations: [Formation] {
        let sorted = (vehicleClass.formations ?? []).sorted { $0.code < $1.code }
        if query.isEmpty { return sorted }
        return sorted.filter { $0.code.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List {
            Section {
                summaryRow
            }
            Section {
                ForEach(formations) { f in
                    NavigationLink(value: f) {
                        FormationRow(formation: f)
                    }
                }
            } header: {
                Text("\(formations.count) \(vehicleClass.unitType.counter)")
            }

            if vehicleClass.isUserAdded || true {
                Section {
                    NavigationLink {
                        AddFormationView(vehicleClass: vehicleClass)
                    } label: {
                        Label("\(vehicleClass.unitType.unitLabel)を追加", systemImage: "plus.circle")
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "\(vehicleClass.unitType.unitLabel)で検索")
        .navigationTitle(vehicleClass.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Formation.self) { FormationDetailView(formation: $0) }
    }

    private var summaryRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(vehicleClass.operatorName, systemImage: "building.2")
                Spacer()
                if vehicleClass.isComplete {
                    Label("コンプリート", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption.bold())
                }
            }
            if !vehicleClass.lineNames.isEmpty {
                Text(vehicleClass.lineNames.joined(separator: " / "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: vehicleClass.collectionRatio)
                .tint(vehicleClass.isComplete ? .yellow : .orange)
            Text("\(vehicleClass.collectedCount) / \(vehicleClass.totalCount) 編成")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

private struct FormationRow: View {
    let formation: Formation
    var body: some View {
        HStack {
            Image(systemName: formation.isCollected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(formation.isCollected ? .green : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(formation.code).font(.body.monospaced())
                if let last = formation.lastSeen {
                    Text("最終: \(last, format: .dateTime.year().month().day())")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if formation.sightingCount > 0 {
                Text("\(formation.sightingCount)回")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            if !formation.isActive {
                Image(systemName: "xmark.bin").foregroundStyle(.red)
            }
        }
    }
}

/// 編成詳細: 遭遇履歴と関連写真
struct FormationDetailView: View {
    let formation: Formation

    private var sightings: [Sighting] {
        (formation.sightings ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("形式", value: formation.vehicleClass?.name ?? "—")
                LabeledContent("編成", value: formation.code)
                LabeledContent("両数", value: "\(formation.carCount)両")
                if let first = formation.firstSeen {
                    LabeledContent("初遭遇", value: first.formatted(date: .abbreviated, time: .omitted))
                }
                if let last = formation.lastSeen {
                    LabeledContent("最終遭遇", value: last.formatted(date: .abbreviated, time: .omitted))
                }
                LabeledContent("遭遇回数", value: "\(formation.sightingCount)")
                if !formation.isActive {
                    Label("廃車済", systemImage: "xmark.bin").foregroundStyle(.red)
                }
            }
            Section("遭遇履歴") {
                if sightings.isEmpty {
                    Text("まだ記録がありません").foregroundStyle(.secondary)
                } else {
                    ForEach(sightings) { s in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(s.date, format: .dateTime.year().month().day())
                                    .font(.caption.monospaced())
                                Spacer()
                                if s.isLastRun {
                                    Text("ラストラン").font(.caption2.bold()).foregroundStyle(.red)
                                }
                            }
                            if let file = s.photoFilenames.first, let img = PhotoStore.load(file) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            Text("\(s.lineName) · \(s.stationName)")
                                .font(.subheadline)
                            if !s.carNumber.isEmpty {
                                Text(s.carNumber).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            if !s.headmark.isEmpty || !s.livery.isEmpty {
                                HStack(spacing: 6) {
                                    if !s.headmark.isEmpty { tag(s.headmark, color: .orange) }
                                    if !s.livery.isEmpty { tag(s.livery, color: .purple) }
                                }
                            }
                            ForEach(s.audioFilenames, id: \.self) { file in
                                AudioPlayerRow(filename: file)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle(formation.code)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
}

#Preview {
    CollectionView()
        .modelContainer(PreviewData.container)
}
