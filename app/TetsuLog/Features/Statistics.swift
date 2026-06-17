import Foundation

/// 鉄ヲタが見たい統計を一気に算出する純粋関数群。
/// UI から直接呼べる。SwiftDataの`@Query`結果を渡す前提。
// MARK: - 駅名・路線名の正規化（集計時の表記ゆれ吸収）

private let stationOperatorPrefixes: [String] = [
    // JR系
    "JR東日本", "JR東海", "JR西日本", "JR北海道", "JR四国", "JR九州", "JR貨物", "JR",
    // 大手私鉄
    "東武", "西武", "京成", "京王", "小田急", "東急", "京急", "京浜急行",
    "東京メトロ", "東京地下鉄", "都営", "メトロ",
    "東京モノレール", "ゆりかもめ", "りんかい",
    "相鉄", "横浜高速", "横浜市営",
    "名鉄", "近鉄", "南海", "京阪", "阪急", "阪神", "山陽", "神戸電鉄",
    "西鉄", "福岡市営",
    "札幌市営", "仙台市営"
]

extension String {
    /// 駅名の正規化キー（集計用）。元データは破壊しない。
    /// 末尾の「駅」を落とし、空白・括弧書きを除去、先頭の事業者プレフィックスを除去。
    /// 大文字小文字・全角半角は揃える。
    static func normalizedStationName(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        // 全角→半角の英数字
        if let conv = (t as NSString).applyingTransform(.fullwidthToHalfwidth, reverse: false) {
            t = conv
        }
        // 括弧書きを落とす: 「新宿（西口）」 -> 「新宿」、半角括弧も同様
        for pat in ["（", "）", "(", ")"] { t = t.replacingOccurrences(of: pat, with: " ") }
        if let r = t.range(of: "  ") { t.replaceSubrange(r, with: " ") }
        t = t.trimmingCharacters(in: .whitespaces)
        // 末尾の「駅」を落とす（例: "新宿駅" -> "新宿"）
        if t.hasSuffix("駅") { t.removeLast() }
        // 先頭の事業者プレフィックスを除去
        for p in stationOperatorPrefixes where t.hasPrefix(p) {
            t.removeFirst(p.count)
            break
        }
        return t.trimmingCharacters(in: .whitespaces)
    }

    /// 路線名の正規化キー（集計用）。
    /// 先頭の事業者プレフィックスを落とし、末尾の「線/本線/新幹線」は保持（識別に必要）。
    /// 「JR東日本山手線」「山手線」「JR 山手線」 -> 「山手線」。
    static func normalizedLineName(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if let conv = (t as NSString).applyingTransform(.fullwidthToHalfwidth, reverse: false) {
            t = conv
        }
        t = t.replacingOccurrences(of: " ", with: "")
        for p in stationOperatorPrefixes where t.hasPrefix(p) {
            t.removeFirst(p.count)
            break
        }
        return t
    }
}

enum Statistics {

    struct Overview {
        var totalSightings: Int
        var totalRides: Int
        var totalRideKm: Double
        var collectedFormations: Int
        var totalRideHours: Double
        var firstRecordDate: Date?
    }

    static func overview(sightings: [Sighting], rides: [RideSegment]) -> Overview {
        let totalKm = rides.map(\.distanceKm).reduce(0, +)
        let totalSec = rides.map(\.durationSec).reduce(0, +)
        let formationsSeen = Set(sightings.compactMap { $0.formation?.id })
        let firstDate = (sightings.map(\.date) + rides.map(\.date)).min()
        return Overview(
            totalSightings: sightings.count,
            totalRides: rides.count,
            totalRideKm: totalKm,
            collectedFormations: formationsSeen.count,
            totalRideHours: Double(totalSec) / 3600.0,
            firstRecordDate: firstDate
        )
    }

    /// 形式別の遭遇回数 Top N
    static func topClasses(sightings: [Sighting], limit: Int = 5) -> [(name: String, count: Int)] {
        let names = sightings.compactMap { $0.formation?.vehicleClass?.name }
        let grouped = Dictionary(grouping: names) { $0 }.mapValues { $0.count }
        return grouped
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    /// 路線別の遭遇回数 Top N（路線名の表記ゆれを統合）
    static func topLines(sightings: [Sighting], limit: Int = 5) -> [(name: String, count: Int)] {
        let names = sightings.map(\.lineName).filter { !$0.isEmpty }
        return rankWithNormalization(names, normalize: String.normalizedLineName, limit: limit)
    }

    /// 駅別の遭遇回数 Top N（「JR新宿」「新宿駅」「新宿」を同一視）
    static func topStations(sightings: [Sighting], limit: Int = 5) -> [(name: String, count: Int)] {
        let names = sightings.map(\.stationName).filter { !$0.isEmpty }
        return rankWithNormalization(names, normalize: String.normalizedStationName, limit: limit)
    }

    /// 正規化キーでグルーピングしつつ、表示名は最頻の原表記を採用する。
    /// 例: ["JR新宿", "新宿駅", "新宿", "新宿駅"] -> 正規化キー "新宿" で4件、表示は "新宿駅"（2回で最多）。
    private static func rankWithNormalization(_ names: [String],
                                              normalize: (String) -> String,
                                              limit: Int) -> [(name: String, count: Int)] {
        struct Bucket { var count: Int = 0; var labelCounts: [String: Int] = [:] }
        var buckets: [String: Bucket] = [:]
        for raw in names {
            let key = normalize(raw)
            guard !key.isEmpty else { continue }
            var b = buckets[key] ?? Bucket()
            b.count += 1
            b.labelCounts[raw, default: 0] += 1
            buckets[key] = b
        }
        return buckets
            .sorted { $0.value.count > $1.value.count }
            .prefix(limit)
            .map { _, b in
                let label = b.labelCounts.max { $0.value < $1.value }?.key ?? ""
                return (label, b.count)
            }
    }

    /// 月別の遭遇数（直近12ヶ月）
    static func monthlySightings(sightings: [Sighting]) -> [(month: Date, count: Int)] {
        let cal = Calendar.current
        let now = Date.now
        return (0..<12).reversed().compactMap { offset -> (Date, Int)? in
            guard let target = cal.date(byAdding: .month, value: -offset, to: now),
                  let range = cal.dateInterval(of: .month, for: target) else { return nil }
            let count = sightings.filter { $0.date >= range.start && $0.date < range.end }.count
            return (range.start, count)
        }
    }

    /// ラストラン記録の件数
    static func lastRunCount(sightings: [Sighting]) -> Int {
        sightings.filter { $0.isLastRun || $0.kind == .lastRun }.count
    }
}
