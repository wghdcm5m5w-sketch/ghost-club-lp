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
        self.monitoredSpots = Dictionary(uniqueKeysWithValues: spots.map { ($0.id, $0) })

        // 既存のジオフェンスをクリアして再設定
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        for spot in spots {
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
}
