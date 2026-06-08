import SwiftUI
import SwiftData

@main
struct TetsuLogApp: App {
    let container: ModelContainer

    init() {
        let types: [any PersistentModel.Type] = [
            VehicleClass.self, Formation.self, Sighting.self,
            RideSegment.self, ShootingSpot.self, WatchItem.self, AbandonedLine.self
        ]

        // 1) App Group + CloudKit の共有ストア（ウィジェット連携・本番構成）
        if let shared = SharedStore.container {
            container = shared
            return
        }

        // 2) CloudKit 名前付きストア（App Group 未設定だが iCloud は使える構成）
        do {
            let config = ModelConfiguration(
                "TetsuLog",
                cloudKitDatabase: .private("iCloud.com.yourname.tetsulog")
            )
            container = try ModelContainer(for: Schema(types), configurations: config)
            return
        } catch {
            // iCloud/CloudKit のエンタイトルメントが無い等で失敗 → ローカルのみで続行
            print("CloudKit ストア初期化に失敗、ローカルにフォールバック: \(error)")
        }

        // 3) ローカルのみ（無料アカウント・最小構成での実機確認用。同期はされない）
        do {
            let local = ModelConfiguration("TetsuLogLocal", cloudKitDatabase: .none)
            container = try ModelContainer(for: Schema(types), configurations: local)
        } catch {
            fatalError("ModelContainer の初期化に失敗: \(error)")
        }
    }

    @State private var rideManager = RideManager()
    @State private var purchaseManager = PurchaseManager()
    @AppStorage("tetsulog.onboardingDone") private var onboardingDone = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingDone {
                    RootTabView()
                        .environment(rideManager)
                        .environment(purchaseManager)
                } else {
                    OnboardingView()
                }
            }
            .task {
                await SeedData.seedIfNeeded(container.mainContext)
                await purchaseManager.loadProducts()
            }
        }
        .modelContainer(container)
    }
}
