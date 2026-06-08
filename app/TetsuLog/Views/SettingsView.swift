import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(PurchaseManager.self) private var store
    @Query private var watchItems: [WatchItem]
    @Query private var sightings: [Sighting]
    @Query private var rides: [RideSegment]
    @AppStorage("tetsulog.lastSyncAt") private var lastSyncAt: Double = 0

    @State private var exportURL: URL?
    @State private var showingShare = false
    @State private var showingImporter = false
    @State private var showingCSVImport = false
    @State private var showingPurchase = false
    @State private var importMessage: String?

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NavyBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        MakuHeader(title: "設 定").padding(.top, 8)

                        // Pro バナー（買い切り課金）
                        proBanner

                        section("あなたの記録") {
                            row("遭遇記録", "\(sightings.count)件")
                            line
                            row("乗車記録", "\(rides.count)件")
                            line
                            row("累計乗車距離", String(format:"%.1f km", rides.map(\.distanceKm).reduce(0,+)))
                        }

                        section("狙いの編成リマインダー") {
                            NavigationLink { WatchListView() } label: {
                                navRow("ウォッチリストを編集", "bell.badge")
                            }
                            caption("登録した形式・編成にちなんだ撮影地・駅に近づくと通知します。※リアルタイムの在線位置ではありません。")
                        }

                        section("プライバシー・データ") {
                            HStack {
                                Label("iCloudにのみ保存", systemImage: "lock.icloud").foregroundStyle(Theme.Palette.navy)
                                    .font(Theme.Font.body(15))
                                Spacer()
                            }
                            if lastSyncAt > 0 {
                                line
                                row("最終同期", Date(timeIntervalSince1970: lastSyncAt).formatted(date:.abbreviated, time:.shortened))
                            }
                            line
                            actionRow("データをJSONで書き出す", "square.and.arrow.up"){ export() }
                            line
                            actionRow("JSONから読み込む（移行・復元）", "square.and.arrow.down"){ showingImporter = true }
                            line
                            actionRow("CSVから取り込む（他サービス）", "tablecells"){ showingCSVImport = true }
                            if let importMessage {
                                caption(importMessage, color: Theme.Palette.navy)
                            }
                            caption("運営者のサーバーには送信されません。※写真・録音は端末内保存のためJSONには含まれません。")
                        }

                        section("アプリ") {
                            row("バージョン", appVersion)
                            line
                            linkRow("プライバシーポリシー", "https://example.github.io/ghost-club-lp/tetsulog-privacy.html")
                            line
                            linkRow("利用規約", "https://example.github.io/ghost-club-lp/tetsulog-terms.html")
                            line
                            linkRow("特定商取引法に基づく表記", "https://example.github.io/ghost-club-lp/tetsulog-tokushoho.html")
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
            .sheet(isPresented: $showingShare) { if let exportURL { ShareSheet(items: [exportURL]) } }
            .sheet(isPresented: $showingCSVImport) { CSVImportSheet() }
            .sheet(isPresented: $showingPurchase) { PurchaseView() }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { handleImport($0) }
        }
    }

    // MARK: Pro バナー
    @ViewBuilder
    private var proBanner: some View {
        if store.isPro {
            Button {
                showingPurchase = true
            } label: {
                PaperCard(accent: false) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Palette.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TetsuLog Pro 有効")
                                .font(.system(size: 15, weight: .heavy, design: .serif))
                                .foregroundStyle(Theme.Palette.ink)
                            Text("ご購入ありがとうございます")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Palette.inkSub)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.Palette.inkSub)
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            Button {
                showingPurchase = true
            } label: {
                PaperCard(accent: true) {
                    HStack(spacing: 12) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.Palette.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TetsuLog Pro")
                                .font(.system(size: 15, weight: .heavy, design: .serif))
                                .foregroundStyle(Theme.Palette.ink)
                            Text("全機能を ¥\(displayPrice) 買い切りで")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Palette.inkSub)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.Palette.inkSub)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var displayPrice: String {
        store.product?.displayPrice
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: ",", with: "")
            ?? "980"
    }

    // MARK: コンポーネント
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.Font.mono(13)).foregroundStyle(Theme.Palette.creamSub).padding(.leading, 6)
            PaperCard(accent: false) { VStack(spacing: 12) { content() } }
        }
    }
    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).font(Theme.Font.body(15)).foregroundStyle(Theme.Palette.ink)
            Spacer(); Text(v).font(Theme.Font.mono(14)).foregroundStyle(Theme.Palette.inkSub) }
    }
    private func navRow(_ k: String, _ icon: String) -> some View {
        HStack { Label(k, systemImage: icon).font(Theme.Font.body(15)).foregroundStyle(Theme.Palette.navy)
            Spacer(); Image(systemName: "chevron.right").foregroundStyle(Theme.Palette.inkSub).font(.system(size:13)) }
    }
    private func actionRow(_ k: String, _ icon: String, _ act: @escaping ()->Void) -> some View {
        Button(action: act) {
            HStack { Label(k, systemImage: icon).font(Theme.Font.body(15)).foregroundStyle(Theme.Palette.navy)
                Spacer() }
        }.buttonStyle(.plain)
    }
    private func linkRow(_ k: String, _ url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack { Text(k).font(Theme.Font.body(15)).foregroundStyle(Theme.Palette.navy)
                Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(Theme.Palette.inkSub).font(.system(size:12)) }
        }
    }
    private func caption(_ t: String, color: Color = Theme.Palette.inkSub) -> some View {
        Text(t).font(Theme.Font.body(12)).foregroundStyle(color).frame(maxWidth:.infinity, alignment:.leading)
    }
    private var line: some View { Rectangle().fill(Theme.Palette.paperEdge).frame(height:1) }

    private func export() {
        if let url = ExportService.exportAll(context) { exportURL = url; showingShare = true; Haptics.success(); lastSyncAt = Date.now.timeIntervalSince1970 }
    }
    private func handleImport(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        if let r = ExportService.importAll(from: url, into: context) {
            importMessage = "読み込み完了: 遭遇\(r.sightings)件・乗車\(r.rides)件・撮影地\(r.spots)件"; Haptics.success()
        } else { importMessage = "読み込みに失敗しました。ファイル形式をご確認ください。" }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

/// ウォッチリスト管理（形式と編成番号の両対応）
struct WatchListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WatchItem.createdAt, order: .reverse) private var items: [WatchItem]
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]
    @State private var newClassName = ""
    @State private var newFormationCode = ""

    var body: some View {
        ZStack {
            NavyBackground()
            ScrollView {
                VStack(spacing: 16) {
                    PaperCard(accent: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("追加").font(Theme.Font.headline(16)).foregroundStyle(Theme.Palette.ink)
                            Picker("形式", selection: $newClassName) {
                                Text("選択").tag("")
                                ForEach(classes){ Text($0.name).tag($0.name) }
                            }.tint(Theme.Palette.navy)
                            TextField("編成番号（任意・例: ナノN102）", text: $newFormationCode)
                                .font(Theme.Font.mono(15)).foregroundStyle(Theme.Palette.ink)
                            Button { add() } label: {
                                Text("ウォッチリストに追加").font(.system(size:15,weight:.bold))
                                    .frame(maxWidth:.infinity).padding(.vertical,10)
                                    .background(RoundedRectangle(cornerRadius:10).fill(newClassName.isEmpty ? Theme.Palette.rail : Theme.Palette.red))
                                    .foregroundStyle(Theme.Palette.paper)
                            }.disabled(newClassName.isEmpty).buttonStyle(.plain)
                        }
                    }
                    if items.isEmpty {
                        Text("まだ登録がありません").font(Theme.Font.body(14)).foregroundStyle(Theme.Palette.creamSub).padding(.top, 20)
                    } else {
                        ForEach(items) { item in
                            PaperCard {
                                HStack {
                                    Image(systemName: "bell.fill").foregroundStyle(Theme.Palette.red)
                                    VStack(alignment:.leading, spacing:2){
                                        Text(item.targetClassName).font(Theme.Font.body(15)).foregroundStyle(Theme.Palette.ink)
                                        if !item.targetFormationCode.isEmpty {
                                            Text(item.targetFormationCode).font(Theme.Font.mono(12)).foregroundStyle(Theme.Palette.inkSub)
                                        }
                                    }
                                    Spacer()
                                    Toggle("", isOn: Binding(get:{item.enabled}, set:{item.enabled=$0; try? context.save()})).labelsHidden().tint(Theme.Palette.red)
                                }
                            }
                            .contextMenu { Button(role:.destructive){ context.delete(item); try? context.save() } label:{ Label("削除",systemImage:"trash") } }
                        }
                    }
                }
                .padding(Theme.screenPadding)
            }
        }
        .navigationTitle("ウォッチリスト")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    private func add() {
        let item = WatchItem(targetClassName: newClassName, targetFormationCode: newFormationCode)
        context.insert(item); try? context.save(); Haptics.tick()
        newClassName=""; newFormationCode=""
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
        .environment(PurchaseManager())
}
