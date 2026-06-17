import Foundation
import UIKit

/// 添付写真を端末内に保存・読み出しする。
/// 画像本体はサイズが大きいためCloudKit同期対象外とし、端末内（Documents/photos）に保存。
/// 記録(Sighting)にはファイル名のみを持たせる。これにより
/// 「写真添付と言いながら保存されない」問題を解消する。
enum PhotoStore {
    private static var dir: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photos = base.appendingPathComponent("photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: photos.path) {
            // Data Protection: 初回ロック解除後のみ復号可（バックグラウンド処理とも両立）
            try? FileManager.default.createDirectory(
                at: photos, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
        }
        return photos
    }

    /// 画像データをJPEGで保存し、ファイル名を返す
    @discardableResult
    static func save(_ data: Data) -> String? {
        // リサイズして容量を抑える（長辺2048）
        let jpeg: Data
        if let image = UIImage(data: data),
           let resized = image.resized(maxDimension: 2048),
           let encoded = resized.jpegData(compressionQuality: 0.82) {
            jpeg = encoded
        } else {
            jpeg = data
        }
        let filename = "\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(filename)
        do {
            try jpeg.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
            return filename
        } catch {
            return nil
        }
    }

    /// ファイル名から画像を読み出す
    static func load(_ filename: String) -> UIImage? {
        let url = dir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// 削除
    static func delete(_ filename: String) {
        let url = dir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    /// ディレクトリ内の全ファイル名
    /// 端末内に保存された全写真ファイルのURL（バックアップ書き出し用）
    static func allFileURLs() -> [URL] {
        allFilenames().map { dir.appendingPathComponent($0) }
    }

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
    /// 記録削除後に画像だけ残ってストレージを食い続ける問題への掃除口。
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

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage? {
        let longSide = max(size.width, size.height)
        guard longSide > maxDimension else { return self }
        let scale = maxDimension / longSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
