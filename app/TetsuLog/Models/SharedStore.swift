import Foundation
import SwiftData

/// アプリ本体・Widget Extension で共有する ModelContainer。
/// App Group のコンテナ内にストアを置くことでウィジェットからも読める。
/// 両ターゲットの Membership にこのファイルと Models.swift を追加すること。
enum SharedStore {
    /// App Group ID（Capabilities で両ターゲットに設定）
    static let appGroupID = "group.com.ryofujimatsu.tetsulog"

    static let container: ModelContainer? = {
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        let storeURL = groupURL.appendingPathComponent("TetsuLog.store")
        let config = ModelConfiguration(
            url: storeURL,
            cloudKitDatabase: .private("iCloud.com.ryofujimatsu.tetsulog")
        )
        return try? ModelContainer(
            for: VehicleClass.self, Formation.self, Sighting.self,
                RideSegment.self, ShootingSpot.self, WatchItem.self, AbandonedLine.self,
            configurations: config
        )
    }()
}
