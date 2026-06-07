import Foundation

/// 順光/逆光の判定結果
enum LightDirection: String {
    case front = "順光"
    case side  = "斜光"
    case back  = "逆光"

    var isGood: Bool { self == .front }
}

struct SunPosition {
    let azimuth: Double   // 度（北=0, 東=90, 南=180, 西=270）
    let altitude: Double  // 度（地平線=0, 天頂=90）
}

/// NOAA Solar Position Algorithm の簡易実装。
/// 撮影計画用の概算（数分・数度の誤差は許容）。
enum SunCalculator {

    static func position(latitude lat: Double, longitude lon: Double, date: Date) -> SunPosition {
        let d2r = Double.pi / 180
        let r2d = 180 / Double.pi

        // ユリウス日
        let jd = julianDay(from: date)
        let n = jd - 2451545.0                       // J2000からの経過日
        let L = (280.460 + 0.9856474 * n)
            .truncatingRemainder(dividingBy: 360)    // 平均黄経
        let g = (357.528 + 0.9856003 * n)
            .truncatingRemainder(dividingBy: 360)    // 平均近点角
        let lambda = L + 1.915 * sin(g * d2r) + 0.020 * sin(2 * g * d2r) // 黄経
        let epsilon = 23.439 - 0.0000004 * n          // 黄道傾斜角

        // 赤道座標
        let alpha = atan2(cos(epsilon * d2r) * sin(lambda * d2r), cos(lambda * d2r)) * r2d
        let delta = asin(sin(epsilon * d2r) * sin(lambda * d2r)) * r2d

        // 時角
        let gmst = (280.46061837 + 360.98564736629 * n)
            .truncatingRemainder(dividingBy: 360)
        let lst = gmst + lon
        var H = lst - alpha
        H = H.truncatingRemainder(dividingBy: 360)
        if H < -180 { H += 360 }
        if H > 180 { H -= 360 }

        // 地平座標
        let latR = lat * d2r
        let deltaR = delta * d2r
        let HR = H * d2r

        let altitude = asin(sin(latR) * sin(deltaR) + cos(latR) * cos(deltaR) * cos(HR)) * r2d
        var azimuth = atan2(-sin(HR), tan(deltaR) * cos(latR) - sin(latR) * cos(HR)) * r2d
        azimuth = (azimuth + 360).truncatingRemainder(dividingBy: 360)

        return SunPosition(azimuth: azimuth, altitude: altitude)
    }

    /// 線路（被写体）方位と太陽方位から順光/逆光を判定
    static func lightDirection(trackBearing: Double, sunAzimuth: Double) -> LightDirection {
        let raw = abs(trackBearing - sunAzimuth)
            .truncatingRemainder(dividingBy: 360)
        let diff = min(raw, 360 - raw)
        switch diff {
        case ..<45:  return .front
        case ..<135: return .side
        default:     return .back
        }
    }

    private static func julianDay(from date: Date) -> Double {
        // Unix epoch (1970-01-01) のユリウス日 = 2440587.5
        return date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }
}
