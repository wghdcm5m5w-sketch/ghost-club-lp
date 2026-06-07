import XCTest
@testable import TetsuLog

final class FormationNumberParserTests: XCTestCase {

    func testCarNumberExtraction() {
        let result = FormationNumberParser.candidates(from: ["クハE235-1247"])
        XCTAssertTrue(result.contains { $0.kind == .carNumber && $0.raw == "クハE235-1247" })
        XCTAssertEqual(result.first { $0.kind == .carNumber }?.classHint, "E235")
    }

    func testCarNumberWithoutLetterPrefix() {
        // モハ223-2034: 形式番号は数字のみ
        let result = FormationNumberParser.candidates(from: ["モハ223-2034"])
        let car = result.first { $0.kind == .carNumber }
        XCTAssertNotNil(car)
        XCTAssertEqual(car?.classHint, "223")
    }

    func testFormationCodeKatakana() {
        let result = FormationNumberParser.candidates(from: ["トウ47"])
        XCTAssertTrue(result.contains { $0.raw == "トウ47" && $0.kind == .formationCode })
    }

    func testFormationCodeAlpha() {
        let result = FormationNumberParser.candidates(from: ["J36", "W1"])
        XCTAssertTrue(result.contains { $0.raw == "J36" })
        XCTAssertTrue(result.contains { $0.raw == "W1" })
    }

    func testNoiseFiltering_FourDigitYear() {
        // 2024 のような4桁数字単独は誤検出として除外される
        let result = FormationNumberParser.candidates(from: ["2024"])
        XCTAssertFalse(result.contains { $0.raw == "2024" })
    }

    func testDuplicateRemoval() {
        let result = FormationNumberParser.candidates(from: ["トウ47", "トウ47"])
        let count = result.filter { $0.raw == "トウ47" }.count
        XCTAssertEqual(count, 1)
    }

    func testFullwidthNormalization() {
        // 全角数字を含むテキスト
        let result = FormationNumberParser.candidates(from: ["クハE235-1247"])
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyInput() {
        XCTAssertTrue(FormationNumberParser.candidates(from: []).isEmpty)
        XCTAssertTrue(FormationNumberParser.candidates(from: [""]).isEmpty)
    }
}
