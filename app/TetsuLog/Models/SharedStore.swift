import Foundation
import SwiftData

/// アプリ本体・Widget Extension・Apple Watch で共有する ModelContainer。
/// App Group のコンテナ内にストアを置くことでウィジェットからも読める。
/// 両ターゲットの Membership にこのファイルと Models.swift を追加すること。
///
/// 重要: 本体は CloudKit ミラーリング付きで開き（書き込み＋iCloud同期）、
/// iCloud エンタイトルメントを持たない拡張（iOS ウィジェット等）は
/// 同じ App Group のファイルを **CloudKit なし** で開いてローカル読み取りを試みる。
/// これにより「iCloud権限が無い拡張ではコンテナが nil → ウィジェットが常にゼロ」を防ぐ。
///
/// 注: 本体が必ず先にストアを生成・マイグレーションする前提のベストエフォート。
/// 万一この .none 読み取りも開けない場合は container == nil となり、
/// ウィジェット側は loaded:false で「アプリを開いて同期」を表示する（フェイルセーフ）。
/// 拡張は決して最初の書き込み手にならない（本体が初期化済みの想定）。
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

    /// 共有ストアがどの構成で開けたか（診断・設定画面の表示用）。
    enum Mode { case cloudKitShared, localShared, unavailable }

    private static let resolved: (container: ModelContainer?, mode: Mode) = {
        guard let storeURL else { return (nil, .unavailable) }

        // 1) 本番（本体・Watch）: CloudKit ミラーリング付きの共有ストア。
        let cloudConfig = ModelConfiguration(
            url: storeURL,
            cloudKitDatabase: .private(cloudKitContainerID)
        )
        if let c = try? ModelContainer(for: Schema(modelTypes), configurations: cloudConfig) {
            return (c, .cloudKitShared)
        }

        // 2) フォールバック: CloudKit エンタイトルメントの無い拡張（iOS ウィジェット等）でも、
        //    本体が CloudKit でミラーした同じ App Group の SQLite を **ローカル読み取り** する。
        let localConfig = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
        if let c = try? ModelContainer(for: Schema(modelTypes), configurations: localConfig) {
            return (c, .localShared)
        }
        return (nil, .unavailable)
    }()

    static var container: ModelContainer? { resolved.container }
    static var mode: Mode { resolved.mode }

    /// シードデータ（形式マスタ）が入っているか。
    /// 拡張が「まだ同期されていない空ストア」を本物のゼロとして表示しないための判定。
    static func isPopulated(_ context: ModelContext) -> Bool {
        let count = (try? context.fetchCount(FetchDescriptor<VehicleClass>())) ?? 0
        return count > 0
    }
}
