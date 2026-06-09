import SwiftUI
import SwiftData

/// Apple Watch コンパニオンアプリ。
/// 本体と同じ CloudKit Private DB を参照し、SwiftDataで読み書き同期する。
/// 共有ファイル: TetsuLog/Models/Models.swift, SharedStore.swift, Features/Haptics.swift
@main
struct TetsuLogWatchApp: App {
    let container: ModelContainer

    init() {
        let types: [any PersistentModel.Type] = [
            VehicleClass.self, Formation.self, Sighting.self,
            RideSegment.self, ShootingSpot.self, WatchItem.self, AbandonedLine.self
        ]
        // 本体と同じ CloudKit コンテナで同期
        if let shared = SharedStore.container {
            container = shared
        } else {
            do {
                let config = ModelConfiguration(
                    "TetsuLog",
                    cloudKitDatabase: .private("iCloud.com.ryofujimatsu.tetsulog")
                )
                container = try ModelContainer(for: Schema(types), configurations: config)
            } catch {
                // 最悪ローカル
                let local = ModelConfiguration("TetsuLogLocal", cloudKitDatabase: .none)
                container = try! ModelContainer(for: Schema(types), configurations: local)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchTodayView()
        }
        .modelContainer(container)
    }
}
