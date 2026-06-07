import Foundation
import ImageIO
import CoreLocation

/// 写真EXIFから撮影日時・位置を端末内で抽出する。外部送信なし。
enum PhotoMetadata {

    struct Info {
        let date: Date?
        let coordinate: CLLocationCoordinate2D?
    }

    static func read(from imageData: Data) -> Info {
        guard let src = CGImageSourceCreateWithData(imageData as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] else {
            return Info(date: nil, coordinate: nil)
        }

        // 撮影日時
        var date: Date?
        if let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let str = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy:MM:dd HH:mm:ss"
            fmt.locale = Locale(identifier: "en_US_POSIX")
            date = fmt.date(from: str)
        }

        // GPS
        var coord: CLLocationCoordinate2D?
        if let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any],
           let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
           let lon = gps[kCGImagePropertyGPSLongitude] as? Double {
            let latRef = (gps[kCGImagePropertyGPSLatitudeRef] as? String) ?? "N"
            let lonRef = (gps[kCGImagePropertyGPSLongitudeRef] as? String) ?? "E"
            let signedLat = (latRef == "S") ? -lat : lat
            let signedLon = (lonRef == "W") ? -lon : lon
            coord = CLLocationCoordinate2D(latitude: signedLat, longitude: signedLon)
        }

        return Info(date: date, coordinate: coord)
    }
}
