import SwiftUI

struct RootTabView: View {
    init() {
        // タブバーを紺基調に
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.Palette.navyDeep)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
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

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
        .environment(RideManager())
        .environment(PurchaseManager())
}
