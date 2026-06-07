import XCTest
import CoreLocation
@testable import TetsuLog

final class PolylineCodecTests: XCTestCase {

    func testDecodeBasic() {
        let s = "35.0,139.0 36.0,140.0"
        let coords = PolylineCodec.decode(s)
        XCTAssertEqual(coords.count, 2)
        XCTAssertEqual(coords[0].latitude, 35.0, accuracy: 0.0001)
        XCTAssertEqual(coords[0].longitude, 139.0, accuracy: 0.0001)
        XCTAssertEqual(coords[1].latitude, 36.0, accuracy: 0.0001)
    }

    func testEncodeBasic() {
        let coords = [
            CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0),
            CLLocationCoordinate2D(latitude: 36.0, longitude: 140.0)
        ]
        let s = PolylineCodec.encode(coords)
        XCTAssertTrue(s.contains("35.0,139.0"))
        XCTAssertTrue(s.contains("36.0,140.0"))
    }

    func testRoundtrip() {
        let coords = [
            CLLocationCoordinate2D(latitude: 43.305, longitude: 143.142),
            CLLocationCoordinate2D(latitude: 43.330, longitude: 143.150),
            CLLocationCoordinate2D(latitude: 43.398, longitude: 143.175)
        ]
        let encoded = PolylineCodec.encode(coords)
        let decoded = PolylineCodec.decode(encoded)
        XCTAssertEqual(decoded.count, coords.count)
        for (a, b) in zip(coords, decoded) {
            XCTAssertEqual(a.latitude, b.latitude, accuracy: 0.0001)
            XCTAssertEqual(a.longitude, b.longitude, accuracy: 0.0001)
        }
    }

    func testDecodeIgnoresMalformed() {
        // 不正な座標は捨てる
        let s = "35.0,139.0 garbage 36.0,140.0"
        let coords = PolylineCodec.decode(s)
        XCTAssertEqual(coords.count, 2)
    }

    func testDecodeEmpty() {
        XCTAssertEqual(PolylineCodec.decode("").count, 0)
    }
}
