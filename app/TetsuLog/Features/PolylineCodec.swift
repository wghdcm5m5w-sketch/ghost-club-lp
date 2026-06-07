import Foundation
import CoreLocation

/// 廃線軌跡の簡易エンコード/デコード。
/// フォーマット: "lat,lon lat,lon ..."（スペース区切りの座標列）。
/// 外部ライブラリ不要・依存ゼロ。本番でGeoJSONを使う場合はここを差し替える。
enum PolylineCodec {
    static func decode(_ encoded: String) -> [CLLocationCoordinate2D] {
        encoded
            .split(separator: " ")
            .compactMap { pair -> CLLocationCoordinate2D? in
                let comps = pair.split(separator: ",")
                guard comps.count == 2,
                      let lat = Double(comps[0]),
                      let lon = Double(comps[1]) else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
    }

    static func encode(_ coords: [CLLocationCoordinate2D]) -> String {
        coords
            .map { "\($0.latitude),\($0.longitude)" }
            .joined(separator: " ")
    }
}
