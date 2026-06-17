import Foundation
import CoreLocation
import UserNotifications

/// 接近アラート: GPSジオフェンス × 静的ダイヤ × ウォッチリストの端末内予測。
/// リアルタイム在線データは扱わない。位置情報は端末外に出さない。
@MainActor
final class ApproachMonitor: NSObject {
    static let shared = ApproachMonitor()

    private let manager = CLLocationManager()
    private var monitoredSpots: [UUID: ShootingSpotRef] = [:]

    /// iOS のリージョン監視上限（アプリあたり20件）。これを超える撮影地は
    /// 現在地から近い順に20件だけ監視する。
    private static let maxRegions = 20
    /// 監視対象の全撮影地（近傍選定の母集団）
    private var allSpots: [ShootingSpotRef] = []
    /// 直近に近傍選定を行った基準地点。ここから大きく動いたら再選定する。
    private var lastSelectionCenter: CLLocation?
    private static let reselectThresholdMeters: CLLocationDistance = 5_000

    /// ウォッチ対象が来る可能性を推定するための簡易ダイヤ参照（本番はGTFSから）
    struct ScheduleWindow {
        let className: String
        let lineName: String
        let startMinute: Int   // 0..1439 一日の中の通過時間帯
        let endMinute: Int
    }

    struct ShootingSpotRef {
        let id: UUID
        let name: String
        let coordinate: CLLocationCoordinate2D
        let lineName: String
    }

    private var schedules: [ScheduleWindow] = []
    private var watchedClassNames: Set<String> = []

    func requestAuthorization() {
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// ウォッチリストと撮影地・ダイヤを設定して監視を開始
    func configure(watchedClassNames: Set<String>,
                   spots: [ShootingSpotRef],
                   schedules: [ScheduleWindow]) {
        self.watchedClassNames = watchedClassNames
        self.schedules = schedules
        self.allSpots = spots

        // 現在地が分かれば近傍20件を、分からなければ先頭20件を監視
        if spots.count > Self.maxRegions {
            manager.startMonitoringSignificantLocationChanges()
            manager.requestLocation()   // 一度だけ現在地を取得 → didUpdateLocations で再選定
        }
        applyMonitoring(near: manager.location)
    }

    /// 現在地（nil可）に近い順に最大20件だけジオフェンス登録する。
    private func applyMonitoring(near location: CLLocation?) {
        let selected: [ShootingSpotRef]
        if let location, allSpots.count > Self.maxRegions {
            selected = allSpots
                .sorted { a, b in
                    location.distance(from: CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude))
                        < location.distance(from: CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude))
                }
                .prefix(Self.maxRegions)
                .map { $0 }
        } else {
            selected = Array(allSpots.prefix(Self.maxRegions))
        }

        monitoredSpots = Dictionary(uniqueKeysWithValues: selected.map { ($0.id, $0) })
        lastSelectionCenter = location

        // 既存のジオフェンスをクリアして再設定
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        for spot in selected {
            let region = CLCircularRegion(
                center: spot.coordinate, radius: 800,
                identifier: spot.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
        }
    }

    /// ジオフェンス進入時、ダイヤ窓と現在時刻を照合して通知判断
    private func handleEntry(spotID: UUID) {
        guard let spot = monitoredSpots[spotID] else { return }

        let now = Calendar.current.dateComponents([.hour, .minute], from: .now)
        let nowMinute = (now.hour ?? 0) * 60 + (now.minute ?? 0)

        // この撮影地の路線で、ウォッチ対象形式が通過しそうな窓を探す
        let candidates = schedules.filter { window in
            window.lineName == spot.lineName
                && watchedClassNames.contains(window.className)
                && nowMinute >= window.startMinute - 15   // 前後15分の余裕
                && nowMinute <= window.endMinute + 15
        }

        guard let hit = candidates.first else { return }
        notify(className: hit.className, spotName: spot.name, lineName: spot.lineName)
    }

    private func notify(className: String, spotName: String, lineName: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(className) を狙うなら今かも"
        content.body = "\(lineName)・\(spotName)付近です。ウォッチ中の車両を思い出させました。（在線位置ではなく目安です）"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

extension ApproachMonitor: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let id = UUID(uuidString: region.identifier) else { return }
        Task { @MainActor in self.handleEntry(spotID: id) }
    }

    /// 現在地が更新されたら、基準地点から十分動いた場合のみ近傍を選び直す。
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            if self.allSpots.count <= Self.maxRegions { return }
            if let center = self.lastSelectionCenter,
               center.distance(from: loc) < Self.reselectThresholdMeters { return }
            self.applyMonitoring(near: loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 位置取得に失敗しても監視自体は先頭20件で継続済み。何もしない。
    }
}
