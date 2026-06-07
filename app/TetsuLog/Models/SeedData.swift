import Foundation
import SwiftData

/// 初回起動時に形式マスタ・編成の初期データを投入する。
/// 本番では bundle 同梱の JSON から読み込む想定。ここでは最小サンプルを直書き。
enum SeedData {
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) async {
        // すでに形式が存在すればスキップ
        let descriptor = FetchDescriptor<VehicleClass>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        for spec in sampleClasses {
            let vc = VehicleClass(name: spec.name, operatorName: spec.op, category: spec.category)
            vc.lineNames = spec.lines
            vc.isRetiring = spec.retiring
            context.insert(vc)

            for code in spec.formations {
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

    private struct AbandonedSpec {
        let name: String
        let opened: Int
        let closed: Int
        let polyline: String   // "lat,lon lat,lon ..."
        let note: String
    }

    // サンプル（座標は概略）。本番は GeoJSON / 有志データから生成。
    private static let sampleAbandonedLines: [AbandonedSpec] = [
        .init(name: "国鉄 士幌線（糠平〜十勝三股）", opened: 1939, closed: 1987,
              polyline: "43.305,143.142 43.330,143.150 43.360,143.160 43.398,143.175",
              note: "タウシュベツ川橋梁で知られる区間"),
        .init(name: "国鉄 篠ノ井線 旧線（明科〜西条）", opened: 1900, closed: 1988,
              polyline: "36.345,137.930 36.360,137.945 36.375,137.960",
              note: "三五山トンネル等の遺構が残る"),
    ]

    private struct ClassSpec {
        let name: String
        let op: String
        let category: String
        let lines: [String]
        let cars: Int
        let retiring: Bool
        let formations: [String]
    }

    private static let sampleClasses: [ClassSpec] = [
        .init(name: "E235系", op: "JR東日本", category: "通勤型",
              lines: ["山手線", "横須賀・総武快速線"], cars: 11, retiring: false,
              formations: (1...50).map { "トウ\($0)" }),
        .init(name: "E233系", op: "JR東日本", category: "通勤型",
              lines: ["中央線", "京浜東北線", "常磐線"], cars: 10, retiring: false,
              formations: (1...30).map { "T\($0)" }),
        .init(name: "189系", op: "JR東日本", category: "特急型",
              lines: ["中央本線"], cars: 6, retiring: true,
              formations: ["N101", "N102", "N103"]),
        .init(name: "N700S", op: "JR東海", category: "新幹線",
              lines: ["東海道新幹線"], cars: 16, retiring: false,
              formations: (1...40).map { "J\($0)" }),
        .init(name: "2100形", op: "京急電鉄", category: "一般型",
              lines: ["京急本線"], cars: 8, retiring: false,
              formations: ["2101", "2109", "2117", "2125", "2133", "2141", "2149", "2157"]),
    ]
}
