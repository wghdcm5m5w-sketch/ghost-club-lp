import Foundation

/// 録音ファイルを端末内に保存・読み出しする。
/// 走行音(VVVF)・駅メロ・車内放送など。サイズ大のためCloudKit同期対象外。
enum AudioStore {
    private static var dir: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audio = base.appendingPathComponent("audio", isDirectory: true)
        if !FileManager.default.fileExists(atPath: audio.path) {
            // Data Protection: 初回ロック解除後のみ復号可。
            // .complete だと画面ロック中の長時間録音が書き込めなくなるためこのクラスを選択。
            try? FileManager.default.createDirectory(
                at: audio, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
        }
        return audio
    }

    /// 新規録音用URL（拡張子 .m4a / AAC）
    static func newRecordingURL() -> URL {
        dir.appendingPathComponent("\(UUID().uuidString).m4a")
    }

    /// ファイル名からURLを得る
    static func url(for filename: String) -> URL {
        dir.appendingPathComponent(filename)
    }

    /// 削除
    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: url(for: filename))
    }

    /// ファイルの再生時間を取得（秒）
    static func duration(_ filename: String) -> TimeInterval? {
        let url = url(for: filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        // 軽量にメタから推定するため AVURLAsset などを使う側で扱う
        return nil
    }
}
