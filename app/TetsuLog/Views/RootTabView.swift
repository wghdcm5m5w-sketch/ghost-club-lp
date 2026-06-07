import SwiftUI

struct RootTabView: View {
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
        .tint(.orange)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
        .environment(RideManager())
}
