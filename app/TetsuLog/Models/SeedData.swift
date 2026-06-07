import Foundation
import SwiftData

/// 初回起動時に形式マスタ・編成・廃線の初期データを投入する。
/// 形式は bundle 同梱の seed_vehicles.json から読み込む。
enum SeedData {

    // MARK: - JSON デコード用

    private struct SeedFile: Decodable {
        let classes: [ClassSpec]
    }

    private struct ClassSpec: Decodable {
        let name: String
        let `operator`: String
        let category: String
        let lines: [String]
        let cars: Int
        let retiring: Bool
        // 編成は「prefix+範囲」または「明示コード」のどちらかで指定
        let formationPrefix: String?
        let from: Int?
        let to: Int?
        let formationCodes: [String]?

        var resolvedCodes: [String] {
            if let codes = formationCodes { return codes }
            guard let from, let to else { return [] }
            let prefix = formationPrefix ?? ""
            return (from...to).map { "\(prefix)\($0)" }
        }
    }

    // MARK: - 投入

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) async {
        let existing = (try? context.fetchCount(FetchDescriptor<VehicleClass>())) ?? 0
        guard existing == 0 else { return }

        for spec in loadClasses() {
            let vc = VehicleClass(name: spec.name, operatorName: spec.operator, category: spec.category)
            vc.lineNames = spec.lines
            vc.isRetiring = spec.retiring
            context.insert(vc)

            for code in spec.resolvedCodes {
                let f = Formation(code: code, carCount: spec.cars)
                f.vehicleClass = vc
                f.isActive = !spec.retiring
                context.insert(f)
            }
        }

        for line in sampleAbandonedLines {
            let al = AbandonedLine(name: line.name)
            al.openedYear = line.opened
            al.closedYear = line.closed
            al.encodedPolyline = line.polyline
            al.note = line.note
            context.insert(al)
        }

        try? context.save()
    }

    private static func loadClasses() -> [ClassSpec] {
        guard let url = Bundle.main.url(forResource: "seed_vehicles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(SeedFile.self, from: data) else {
            // JSONが無い場合の最小フォールバック
            return [ClassSpec(name: "E235系", operator: "JR東日本", category: "通勤型",
                              lines: ["山手線"], cars: 11, retiring: false,
                              formationPrefix: "トウ", from: 1, to: 50, formationCodes: nil)]
        }
        return file.classes
    }

    // MARK: - 廃線（サンプル。本番は GeoJSON / 有志データから）

    private struct AbandonedSpec {
        let name: String
        let opened: Int
        let closed: Int
        let polyline: String
        let note: String
    }

    private static let sampleAbandonedLines: [AbandonedSpec] = [
        .init(name: "国鉄 士幌線（糠平〜十勝三股）", opened: 1939, closed: 1987,
              polyline: "43.305,143.142 43.330,143.150 43.360,143.160 43.398,143.175",
              note: "タウシュベツ川橋梁で知られる区間"),
        .init(name: "国鉄 篠ノ井線 旧線（明科〜西条）", opened: 1900, closed: 1988,
              polyline: "36.345,137.930 36.360,137.945 36.375,137.960",
              note: "三五山トンネル等の遺構が残る"),
    ]
}
