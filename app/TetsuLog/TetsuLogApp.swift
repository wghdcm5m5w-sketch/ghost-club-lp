import SwiftUI
import SwiftData

@main
struct TetsuLogApp: App {
    let container: ModelContainer

    init() {
        // App Group 上の共有ストア（ウィジェットと共有）を優先
        if let shared = SharedStore.container {
            container = shared
        } else {
            // App Group 未設定時のフォールバック（開発初期用）
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
                fatalError("ModelContainer の初期化に失敗: \(error)")
            }
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
