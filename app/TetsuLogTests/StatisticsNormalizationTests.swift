import XCTest
@testable import TetsuLog

/// 駅名・路線名の正規化キーのテスト。
/// 表記ゆれを統合した集計（topStations/topLines）の挙動を保証する。
final class StatisticsNormalizationTests: XCTestCase {

    // MARK: - 駅名

    func testStationStripsTrailingEki() {
        XCTAssertEqual(String.normalizedStationName("新宿駅"), "新宿")
        XCTAssertEqual(String.normalizedStationName("新宿"), "新宿")
    }

    func testStationStripsOperatorPrefix() {
        XCTAssertEqual(String.normalizedStationName("JR新宿"), "新宿")
        XCTAssertEqual(String.normalizedStationName("JR東日本 新宿駅"), "新宿")
        XCTAssertEqual(String.normalizedStationName("京急横浜"), "横浜")
        XCTAssertEqual(String.normalizedStationName("東京メトロ大手町"), "大手町")
    }

    func testStationStripsParenthesizedQualifier() {
        XCTAssertEqual(String.normalizedStationName("新宿（西口）"), "新宿")
        XCTAssertEqual(String.normalizedStationName("品川(港南口)"), "品川")
    }

    func testStationEmptyAndWhitespace() {
        XCTAssertEqual(String.normalizedStationName(""), "")
        XCTAssertEqual(String.normalizedStationName("  "), "")
        XCTAssertEqual(String.normalizedStationName("  東京  "), "東京")
    }

    // MARK: - 路線

    func testLineStripsOperatorPrefix() {
        XCTAssertEqual(String.normalizedLineName("JR山手線"), "山手線")
        XCTAssertEqual(String.normalizedLineName("JR東日本 山手線"), "山手線")
        XCTAssertEqual(String.normalizedLineName("山手線"), "山手線")
        XCTAssertEqual(String.normalizedLineName("東急東横線"), "東横線")
    }

    func testLineKeepsLineSuffix() {
        // 線種は識別に必要なので保持される
        XCTAssertEqual(String.normalizedLineName("中央本線"), "中央本線")
        XCTAssertEqual(String.normalizedLineName("東海道新幹線"), "東海道新幹線")
    }

    // MARK: - 集計（topStations）の統合

    func testTopStationsMergesVariants() {
        let sightings = [
            sighting(station: "新宿駅"),
            sighting(station: "JR新宿"),
            sighting(station: "新宿"),
            sighting(station: "新宿（東口）"),
            sighting(station: "渋谷"),
        ]
        let result = Statistics.topStations(sightings: sightings, limit: 5)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].count, 4)            // 新宿が4件に統合
        XCTAssertEqual(result[1].count, 1)            // 渋谷
        // 最頻の原表記が表示名として採用される（"新宿駅", "JR新宿", "新宿", "新宿（東口）" がそれぞれ1件 → 同数なので任意1つ）
        XCTAssertFalse(result[0].name.isEmpty)
    }

    func testTopLinesMergesVariants() {
        let sightings = [
            sighting(line: "JR山手線"),
            sighting(line: "山手線"),
            sighting(line: "山手線"),
            sighting(line: "JR中央本線"),
        ]
        let result = Statistics.topLines(sightings: sightings, limit: 5)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].count, 3)            // 山手線
        XCTAssertEqual(result[1].count, 1)            // 中央本線
    }

    // MARK: - helpers

    private func sighting(station: String = "", line: String = "") -> Sighting {
        Sighting(date: .now, stationName: station, lineName: line)
    }
}
