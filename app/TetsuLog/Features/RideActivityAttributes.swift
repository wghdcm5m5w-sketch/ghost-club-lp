import Foundation
import ActivityKit

/// 乗車セッションのライブアクティビティ属性。
/// アプリ本体と Widget Extension の両ターゲットに含める。
struct RideAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var nextStation: String
        var elapsedSec: Int
        var distanceKm: Double
        var progress: Double   // 0...1 区間内の進捗
    }

    var formationCode: String
    var className: String
    var lineName: String
}

/// 乗車セッション制御。APNsを使わず端末内でローカル更新（サーバー不要・無料維持）。
@MainActor
final class RideSessionController {
    static let shared = RideSessionController()
    private var activity: Activity<RideAttributes>?
    private var startDate: Date?
    private var timer: Timer?

    func start(className: String, formationCode: String, lineName: String, nextStation: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = RideAttributes(
            formationCode: formationCode, className: className, lineName: lineName
        )
        let initial = RideAttributes.ContentState(
            nextStation: nextStation, elapsedSec: 0, distanceKm: 0, progress: 0
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initial, staleDate: nil)
            )
            startDate = .now
            startTimer()
        } catch {
            print("Live Activity 開始失敗: \(error)")
        }
    }

    func update(nextStation: String, distanceKm: Double, progress: Double) async {
        guard let activity, let startDate else { return }
        let elapsed = Int(Date.now.timeIntervalSince(startDate))
        let state = RideAttributes.ContentState(
            nextStation: nextStation, elapsedSec: elapsed,
            distanceKm: distanceKm, progress: progress
        )
        await activity.update(.init(state: state, staleDate: nil))
    }

    func end() async {
        timer?.invalidate(); timer = nil
        guard let activity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        self.activity = nil
        self.startDate = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.startDate else { return }
                let elapsed = Int(Date.now.timeIntervalSince(start))
                // 実際は CoreLocation の移動距離・次駅で更新する。ここでは経過時間のみ反映。
                await self.activity?.update(.init(
                    state: .init(nextStation: "—", elapsedSec: elapsed, distanceKm: 0, progress: 0),
                    staleDate: nil
                ))
            }
        }
    }
}
