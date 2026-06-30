import Foundation

/// 実際に確定した保存先。起動時に TetsuLogApp が設定し、設定画面が表示する。
/// 「iCloudにのみ保存」と謳いながら実際はローカルへ静かにフォールバックする、
/// という表示と実態のズレを防ぐための診断情報。
enum StorageStatus {
    case cloudShared   // App Group + CloudKit（本番・ウィジェット連携あり）
    case cloudNamed    // CloudKit 名前付きストア（App Group なし）
    case localOnly     // ローカルのみ（iCloud に接続できず同期なし）
    case unknown

    /// 起動時に一度だけ設定する（メインスレッド）。
    nonisolated(unsafe) static var current: StorageStatus = .unknown

    var syncsToICloud: Bool {
        switch self {
        case .cloudShared, .cloudNamed: return true
        case .localOnly, .unknown: return false
        }
    }

    var title: String {
        switch self {
        case .cloudShared, .cloudNamed: return "iCloudに同期"
        case .localOnly: return "この端末のみ"
        case .unknown: return "確認中…"
        }
    }

    var detail: String {
        switch self {
        case .cloudShared:
            return "記録はこの端末とあなたのiCloud（非公開）に保存され、同じApple IDの端末・ウィジェット・Apple Watchと同期します。運営者のサーバーには送信されません。"
        case .cloudNamed:
            return "記録はあなたのiCloud（非公開）に保存・同期します。運営者のサーバーには送信されません。"
        case .localOnly:
            return "iCloudに接続できないため、記録はこの端末内にのみ保存されます（同期されません）。iOSの設定でiCloudサインインとiCloud Driveをご確認ください。バックアップはJSON/メディア書き出しをご利用ください。"
        case .unknown:
            return "保存先を確認しています。"
        }
    }

    var icon: String {
        switch self {
        case .cloudShared, .cloudNamed: return "lock.icloud"
        case .localOnly: return "icloud.slash"
        case .unknown: return "lock"
        }
    }
}
