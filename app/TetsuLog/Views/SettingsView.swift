import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var watchItems: [WatchItem]
    @Query private var sightings: [Sighting]
    @Query private var rides: [RideSegment]

    var body: some View {
        NavigationStack {
            Form {
                Section("あなたの記録") {
                    LabeledContent("遭遇記録", value: "\(sightings.count)件")
                    LabeledContent("乗車記録", value: "\(rides.count)件")
                }

                Section {
                    NavigationLink {
                        WatchListView()
                    } label: {
                        Label("ウォッチリスト", systemImage: "bell.badge")
                    }
                } header: {
                    Text("接近アラート")
                } footer: {
                    Text("登録した形式・編成が走るエリアに近づくと、内蔵ダイヤをもとに通知します。リアルタイムの在線位置ではなく、会える可能性の予測です。")
                }

                Section {
                    Label("iCloudにのみ保存されています", systemImage: "lock.icloud")
                        .foregroundStyle(.green)
                } header: {
                    Text("プライバシー")
                } footer: {
                    Text("あなたのデータは運営者のサーバーに送信されません。すべてあなたのiCloud内で端末間同期されます。")
                }

                Section("アプリ") {
                    LabeledContent("バージョン", value: "1.0.0")
                    Link("プライバシーポリシー", destination: URL(string: "https://yourname.github.io/tetsulog/privacy")!)
                    Link("利用規約", destination: URL(string: "https://yourname.github.io/tetsulog/terms")!)
                }
            }
            .navigationTitle("設定")
        }
    }
}

/// ウォッチリスト管理
struct WatchListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WatchItem.createdAt, order: .reverse) private var items: [WatchItem]
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]

    @State private var newClassName = ""

    var body: some View {
        List {
            Section("追加") {
                Picker("形式を追加", selection: $newClassName) {
                    Text("選択").tag("")
                    ForEach(classes) { Text($0.name).tag($0.name) }
                }
                Button("ウォッチリストに追加") { add() }
                    .disabled(newClassName.isEmpty)
            }

            Section("登録中") {
                if items.isEmpty {
                    Text("まだ登録がありません")
                        .foregroundStyle(.secondary)
                }
                ForEach(items) { item in
                    HStack {
                        Image(systemName: "bell.fill").foregroundStyle(.orange)
                        Text(item.displayName)
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
        let item = WatchItem(targetClassName: newClassName)
        context.insert(item)
        try? context.save()
        newClassName = ""
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
