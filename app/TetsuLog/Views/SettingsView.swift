import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var watchItems: [WatchItem]
    @Query private var sightings: [Sighting]
    @Query private var rides: [RideSegment]

    @AppStorage("tetsulog.lastSyncAt") private var lastSyncAt: Double = 0

    @State private var exportURL: URL?
    @State private var showingShare = false
    @State private var showingImporter = false
    @State private var importMessage: String?

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("あなたの記録") {
                    LabeledContent("遭遇記録", value: "\(sightings.count)件")
                    LabeledContent("乗車記録", value: "\(rides.count)件")
                    let km = rides.map(\.distanceKm).reduce(0, +)
                    LabeledContent("累計乗車距離", value: String(format: "%.1f km", km))
                }

                Section {
                    Label("iCloudにのみ保存されています", systemImage: "lock.icloud")
                        .foregroundStyle(.green)
                    if lastSyncAt > 0 {
                        LabeledContent("最終同期", value: Date(timeIntervalSince1970: lastSyncAt)
                            .formatted(date: .abbreviated, time: .shortened))
                    }
                    Button {
                        export()
                    } label: {
                        Label("データをJSONで書き出す", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showingImporter = true
                    } label: {
                        Label("JSONから読み込む（移行・復元）", systemImage: "square.and.arrow.down")
                    }
                    if let importMessage {
                        Text(importMessage).font(.caption).foregroundStyle(.green)
                    }
                } header: {
                    Text("プライバシー・データ")
                } footer: {
                    Text("あなたのデータは運営者のサーバーに送信されません。すべてあなたのiCloud内で端末間同期されます。いつでもJSONで書き出し・読み込みができ、サービスが終了してもデータは手元に残ります。")
                }

                Section {
                    NavigationLink {
                        WatchListView()
                    } label: {
                        Label("ウォッチリストを編集", systemImage: "bell.badge")
                    }
                } header: {
                    Text("狙いの編成リマインダー")
                } footer: {
                    Text("登録した形式・編成にちなんだ撮影地・駅に近づくと、思い出させる通知を出します。※リアルタイムの在線位置ではありません。ダイヤ照合は対応路線で順次有効化されます。")
                }

                Section("アプリ") {
                    LabeledContent("バージョン", value: appVersion)
                    Link("プライバシーポリシー", destination: URL(string: "https://example.github.io/ghost-club-lp/tetsulog-privacy.html")!)
                    Link("利用規約", destination: URL(string: "https://example.github.io/ghost-club-lp/tetsulog-terms.html")!)
                    Link("特定商取引法に基づく表記", destination: URL(string: "https://example.github.io/ghost-club-lp/tetsulog-tokushoho.html")!)
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showingShare) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .fileImporter(isPresented: $showingImporter,
                          allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        if let r = ExportService.importAll(from: url, into: context) {
            importMessage = "読み込み完了: 遭遇\(r.sightings)件・乗車\(r.rides)件・撮影地\(r.spots)件"
            Haptics.success()
        } else {
            importMessage = "読み込みに失敗しました。ファイル形式をご確認ください。"
        }
    }

    private func export() {
        if let url = ExportService.exportAll(context) {
            exportURL = url
            showingShare = true
            Haptics.success()
            lastSyncAt = Date.now.timeIntervalSince1970
        }
    }
}

/// 共有シート
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// ウォッチリスト管理（形式と編成番号の両対応）
struct WatchListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WatchItem.createdAt, order: .reverse) private var items: [WatchItem]
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]

    @State private var newClassName = ""
    @State private var newFormationCode = ""

    var body: some View {
        List {
            Section {
                Picker("形式", selection: $newClassName) {
                    Text("選択").tag("")
                    ForEach(classes) { Text($0.name).tag($0.name) }
                }
                TextField("編成番号（任意・例: ナノN102）", text: $newFormationCode)
                    .font(.body.monospaced())
                Button("ウォッチリストに追加") { add() }
                    .disabled(newClassName.isEmpty)
            } header: {
                Text("追加")
            } footer: {
                Text("編成番号を指定すると、その編成だけにアラートが絞られます。")
            }

            Section("登録中") {
                if items.isEmpty {
                    Text("まだ登録がありません")
                        .foregroundStyle(.secondary)
                }
                ForEach(items) { item in
                    HStack {
                        Image(systemName: "bell.fill").foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.targetClassName)
                            if !item.targetFormationCode.isEmpty {
                                Text(item.targetFormationCode)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { item.enabled },
                            set: { item.enabled = $0; try? context.save() }
                        ))
                        .labelsHidden()
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("ウォッチリスト")
    }

    private func add() {
        let item = WatchItem(targetClassName: newClassName,
                             targetFormationCode: newFormationCode)
        context.insert(item)
        try? context.save()
        Haptics.tick()
        newClassName = ""
        newFormationCode = ""
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(items[i]) }
        try? context.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
