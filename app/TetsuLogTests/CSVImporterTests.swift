import XCTest
@testable import TetsuLog

final class CSVImporterTests: XCTestCase {

    // MARK: - parse

    func testSimpleParse() {
        let csv = "a,b,c\n1,2,3\n"
        let rows = CSVImporter.parse(csv)
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0], ["a", "b", "c"])
        XCTAssertEqual(rows[1], ["1", "2", "3"])
    }

    func testQuotedFieldWithComma() {
        // クォート内のカンマはフィールド区切りにならない
        let csv = "name,note\n\"Tanaka, T.\",hello\n"
        let rows = CSVImporter.parse(csv)
        XCTAssertEqual(rows[1], ["Tanaka, T.", "hello"])
    }

    func testQuotedFieldWithNewline() {
        // クォート内の改行はフィールド内文字
        let csv = "a,b\n\"line1\nline2\",x\n"
        let rows = CSVImporter.parse(csv)
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[1][0], "line1\nline2")
    }

    func testEscapedQuote() {
        // CSVでは "" がエスケープされたダブルクォート
        let csv = "a,b\n\"she said \"\"hi\"\"\",x\n"
        let rows = CSVImporter.parse(csv)
        XCTAssertEqual(rows[1][0], "she said \"hi\"")
    }

    func testEmptyFields() {
        let csv = "a,b,c\n,,\n"
        let rows = CSVImporter.parse(csv)
        XCTAssertEqual(rows[1], ["", "", ""])
    }

    func testTrailingNewlineIgnored() {
        let csv = "a,b\n1,2\n\n"
        let rows = CSVImporter.parse(csv)
        XCTAssertEqual(rows.count, 2)
    }

    // MARK: - suggestMapping

    func testMappingJapaneseHeaders() {
        let m = CSVImporter.suggestMapping(headers: ["乗車日", "路線名", "駅名", "車両形式", "編成番号", "備考"])
        XCTAssertEqual(m[.date], 0)
        XCTAssertEqual(m[.lineName], 1)
        XCTAssertEqual(m[.stationName], 2)
        XCTAssertEqual(m[.className], 3)
        XCTAssertEqual(m[.formationCode], 4)
        XCTAssertEqual(m[.note], 5)
    }

    func testMappingEnglishHeaders() {
        let m = CSVImporter.suggestMapping(headers: ["date", "line", "station", "class", "formation", "note"])
        XCTAssertEqual(m[.date], 0)
        XCTAssertEqual(m[.lineName], 1)
        XCTAssertEqual(m[.stationName], 2)
        XCTAssertEqual(m[.className], 3)
        XCTAssertEqual(m[.formationCode], 4)
        XCTAssertEqual(m[.note], 5)
    }

    func testMappingMixed() {
        // 関連の薄い列名は無視
        let m = CSVImporter.suggestMapping(headers: ["ID", "Date", "Unknown", "駅"])
        XCTAssertEqual(m[.date], 1)
        XCTAssertEqual(m[.stationName], 3)
        XCTAssertNil(m[.lineName])
    }

    // MARK: - parseDate

    func testParseDate_Iso() {
        XCTAssertNotNil(CSVImporter.parseDate("2024-06-21T12:00:00Z"))
    }

    func testParseDate_DashAndSpace() {
        XCTAssertNotNil(CSVImporter.parseDate("2024-06-21 12:00:00"))
    }

    func testParseDate_SlashShort() {
        XCTAssertNotNil(CSVImporter.parseDate("2024/06/21"))
    }

    func testParseDate_Dot() {
        XCTAssertNotNil(CSVImporter.parseDate("2024.06.21"))
    }

    func testParseDate_Invalid() {
        XCTAssertNil(CSVImporter.parseDate("not a date"))
        XCTAssertNil(CSVImporter.parseDate(""))
    }
}
