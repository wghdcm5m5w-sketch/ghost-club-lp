import SwiftUI
import UIKit

/// ルート。iPhone(コンパクト幅)は従来のタブ、iPad(レギュラー幅)はサイドバー2列。
struct RootTabView: View {
    @Environment(\.horizontalSizeClass) private var hSize

    init() {
        // タブバーを紺基調に
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.Palette.navyDeep)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        if hSize == .regular {
            SidebarRootView()
        } else {
            tabView
        }
    }

    private var tabView: some View {
        TabView {
            CollectionView()
                .tabItem { Label("図鑑", systemImage: "square.grid.2x2") }
            LogView()
                .tabItem { Label("記録", systemImage: "list.bullet.rectangle") }
            MapTabView()
                .tabItem { Label("地図", systemImage: "map") }
            StatsView()
                .tabItem { Label("統計", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
        .tint(Theme.Palette.red)
    }
}

/// iPad 向けの2列レイアウト（サイドバー＋詳細）。
/// 各セクションView は内部に自前の NavigationStack を持つのでそのまま詳細列に置ける。
private struct SidebarRootView: View {
    enum Section: String, CaseIterable, Identifiable {
        case zukan = "図鑑", kiroku = "記録", chizu = "地図", toukei = "統計", settei = "設定"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .zukan: return "square.grid.2x2"
            case .kiroku: return "list.bullet.rectangle"
            case .chizu: return "map"
            case .toukei: return "chart.bar.fill"
            case .settei: return "gearshape"
            }
        }
    }

    @State private var selection: Section? = .zukan

    var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $selection) { sec in
                Label(sec.rawValue, systemImage: sec.icon)
                    .tag(sec)
            }
            .navigationTitle("TetsuLog")
            .listStyle(.sidebar)
            .tint(Theme.Palette.red)
        } detail: {
            switch selection ?? .zukan {
            case .zukan:  CollectionView()
            case .kiroku: LogView()
            case .chizu:  MapTabView()
            case .toukei: StatsView()
            case .settei: SettingsView()
            }
        }
        .tint(Theme.Palette.red)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
        .environment(RideManager())
        .environment(PurchaseManager())
}
