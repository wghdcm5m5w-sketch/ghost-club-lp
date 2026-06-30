import Foundation
import SwiftData

/// アプリ本体・Widget Extension・Apple Watch で共有する ModelContainer。
/// App Group のコンテナ内にストアを置くことでウィジェットからも読める。
/// 両ターゲットの Membership にこのファイルと Models.swift を追加すること。
///
/// 重要: 本体は CloudKit ミラーリング付きで開き（書き込み＋iCloud同期）、
/// iCloud エンタイトルメントを持たない拡張（iOS ウィジェット等）は
/// 同じ App Group のファイルを **CloudKit なし** で開いてローカル読み取りする。
/// これにより「iCloud権限が無い拡張ではコンテナが nil → ウィジェットが常にゼロ」を防ぐ。
enum SharedStore {
    /// App Group ID（Capabilities で全ターゲットに設定）
    static let appGroupID = "group.com.ryofujimatsu.tetsulog"
    /// CloudKit Private DB コンテナ ID（本体・Watch で設定）
    static let cloudKitContainerID = "iCloud.com.ryofujimatsu.tetsulog"

    private static let modelTypes: [any PersistentModel.Type] = [
        VehicleClass.self, Formation.self, Sighting.self,
        RideSegment.self, ShootingSpot.self, WatchItem.self, AbandonedLine.self
    ]

    /// App Group 内の共有ストア URL（本体・拡張で同一ファイルを指す）
    static var storeURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("TetsuLog.store")
    }

    static let container: ModelContainer? = {
        guard let storeURL else { return nil }

        // 1) 本番（本体・Watch）: CloudKit ミラーリング付きの共有ストア。
        let cloudConfig = ModelConfiguration(
            url: storeURL,
            cloudKitDatabase: .private(cloudKitContainerID)
        )
        if let c = try? ModelContainer(for: Schema(modelTypes), configurations: cloudConfig) {
            return c
        }

        // 2) フォールバック: CloudKit エンタイトルメントの無い拡張（iOS ウィジェット等）でも、
        //    本体が CloudKit でミラーした同じ App Group の SQLite を **ローカル読み取り** する。
        let localConfig = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
        return try? ModelContainer(for: Schema(modelTypes), configurations: localConfig)
    }()

    /// シードデータ（形式マスタ）が入っているか。
    /// 拡張が「まだ同期されていない空ストア」を本物のゼロとして表示しないための判定。
    static func isPopulated(_ context: ModelContext) -> Bool {
        let count = (try? context.fetchCount(FetchDescriptor<VehicleClass>())) ?? 0
        return count > 0
    }
}
