import SwiftUI
import SwiftData

@main
struct TetsuLogApp: App {
    let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(
                "TetsuLog",
                cloudKitDatabase: .private("iCloud.com.yourname.tetsulog")
            )
            container = try ModelContainer(
                for: VehicleClass.self, Formation.self, Sighting.self,
                    RideSegment.self, ShootingSpot.self, WatchItem.self, AbandonedLine.self,
                configurations: config
            )
        } catch {
            // 開発中はクラッシュさせて原因を顕在化させる
            fatalError("ModelContainer の初期化に失敗: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task {
                    await SeedData.seedIfNeeded(container.mainContext)
                }
        }
        .modelContainer(container)
    }
}
