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

    /// ディレクトリ内の全ファイル名
    static func allFilenames() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
    }

    /// 使用バイト数
    static func diskUsage() -> Int {
        let fm = FileManager.default
        return allFilenames().reduce(0) { sum, name in
            let path = dir.appendingPathComponent(name).path
            let size = (try? fm.attributesOfItem(atPath: path))?[.size] as? Int ?? 0
            return sum + size
        }
    }

    /// どの記録からも参照されていないファイルを削除し、(件数, 解放バイト数) を返す。
    static func removeOrphans(referenced: Set<String>) -> (count: Int, bytes: Int) {
        let fm = FileManager.default
        var count = 0
        var bytes = 0
        for name in allFilenames() where !referenced.contains(name) {
            let path = dir.appendingPathComponent(name).path
            let size = (try? fm.attributesOfItem(atPath: path))?[.size] as? Int ?? 0
            if (try? fm.removeItem(atPath: path)) != nil {
                count += 1
                bytes += size
            }
        }
        return (count, bytes)
    }
}
