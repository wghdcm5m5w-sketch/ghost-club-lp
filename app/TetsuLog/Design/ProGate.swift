import SwiftUI

/// Pro機能のゲーティング用コンポーネント。
/// 無料層と有料層の境界を、世界観を壊さず・誠実に提示する。
///
/// 方針:
/// - 基本記録（図鑑・遭遇記録・乗車記録・地図・統計・撮影地閲覧）は無料
/// - データ持ち出し（JSON/CSVエクスポート・インポート）は信頼の核なので無料
/// - Proは「便利機能」：OCR / 順光計算 / 録音 / ライブアクティビティ
enum Pro {
    /// Pro機能の識別（コピー出し分け用）
    enum Feature: String {
        case ocr = "カメラOCR"
        case sun = "順光計算"
        case audio = "走行音の録音"
        case liveActivity = "ライブアクティビティ"
        case approach = "接近アラート"

        var blurb: String {
            switch self {
            case .ocr: return "写真から編成番号を自動で読み取ります。"
            case .sun: return "撮影地と日時から順光・逆光を計算します。"
            case .audio: return "走行音・駅メロを記録に添付できます。"
            case .liveActivity: return "乗車中をロック画面とDynamic Islandに表示します。"
            case .approach: return "狙いの編成が近いエリアで思い出させます。"
            }
        }
    }
}

/// 金の「PRO」バッジ
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .heavy, design: .serif))
            .tracking(1.5)
            .foregroundStyle(Theme.Palette.navy)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Capsule().fill(Theme.Palette.gold))
    }
}

extension View {
    /// Pro機能のボタンに付ける。未購入なら onLocked（ペイウォール提示）、購入済みなら action を実行。
    /// ボタンのラベル右側にPROバッジを出すのは呼び出し側で行う。
    func proAction(isPro: Bool, onUnlocked: @escaping () -> Void, onLocked: @escaping () -> Void) -> some View {
        self.onTapGesture {
            if isPro { onUnlocked() } else { onLocked() }
        }
    }
}
