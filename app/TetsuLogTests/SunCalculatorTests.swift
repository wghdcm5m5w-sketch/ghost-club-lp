import XCTest
@testable import TetsuLog

/// 太陽位置の概算アルゴリズムが「現実離れしない」範囲に収まっているかを検証。
/// NOAAアルゴリズムは数分・数度の誤差が許容範囲なので、厳密値ではなく合理的範囲で検証。
final class SunCalculatorTests: XCTestCase {

    // 東京駅
    private let tokyoLat = 35.6812
    private let tokyoLon = 139.7671

    private func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        return f.date(from: s)!
    }

    func testNighttimeAltitudeBelowZero() {
        // 真夜中の東京: 太陽は地平線下
        let midnight = date("2026-06-21T15:00:00Z") // = JST 24:00
        let pos = SunCalculator.position(latitude: tokyoLat, longitude: tokyoLon, date: midnight)
        XCTAssertLessThan(pos.altitude, 0,
                          "深夜の太陽高度は負（地平線下）であるべき: \(pos.altitude)")
    }

    func testDaytimeAltitudeAboveZero() {
        // 夏至の正午JST: 東京で太陽は高い位置
        let noon = date("2026-06-21T03:00:00Z") // = JST 12:00
        let pos = SunCalculator.position(latitude: tokyoLat, longitude: tokyoLon, date: noon)
        XCTAssertGreaterThan(pos.altitude, 60,
                             "夏至正午の東京では太陽高度は60°超のはず: \(pos.altitude)")
    }

    func testNoonAzimuthIsSouthish() {
        // 正午前後の太陽方位はほぼ南（180°）付近
        let noon = date("2026-06-21T03:00:00Z")
        let pos = SunCalculator.position(latitude: tokyoLat, longitude: tokyoLon, date: noon)
        XCTAssertGreaterThan(pos.azimuth, 90)
        XCTAssertLessThan(pos.azimuth, 270,
                          "正午の太陽は東(90°)〜西(270°)の南半球側にあるはず: \(pos.azimuth)")
    }

    func testWinterAltitudeLower() {
        // 同じ正午JSTでも、冬至は夏至より太陽高度が低い
        let summer = date("2026-06-21T03:00:00Z")
        let winter = date("2026-12-22T03:00:00Z")
        let sPos = SunCalculator.position(latitude: tokyoLat, longitude: tokyoLon, date: summer)
        let wPos = SunCalculator.position(latitude: tokyoLat, longitude: tokyoLon, date: winter)
        XCTAssertGreaterThan(sPos.altitude, wPos.altitude,
                             "夏至の正午は冬至の正午より太陽高度が高いはず")
    }

    // MARK: - lightDirection

    func testFrontLight() {
        // 線路方位180°(南向き) × 太陽方位180°(南) = 順光
        let d = SunCalculator.lightDirection(trackBearing: 180, sunAzimuth: 180)
        XCTAssertEqual(d, .front)
    }

    func testBackLight() {
        // 線路方位180° × 太陽方位0°(北) = 逆光
        let d = SunCalculator.lightDirection(trackBearing: 180, sunAzimuth: 0)
        XCTAssertEqual(d, .back)
    }

    func testSideLight() {
        // 線路方位180° × 太陽方位90°(東) = 斜光
        let d = SunCalculator.lightDirection(trackBearing: 180, sunAzimuth: 90)
        XCTAssertEqual(d, .side)
    }

    func testWraparound() {
        // 方位の境界(0と360)で誤判定しないこと
        let d1 = SunCalculator.lightDirection(trackBearing: 10, sunAzimuth: 350) // 20°差 → 順光
        XCTAssertEqual(d1, .front)
    }
}
