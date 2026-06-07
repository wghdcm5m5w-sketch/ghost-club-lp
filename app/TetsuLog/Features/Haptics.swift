import UIKit

/// 鉄ヲタ向けの情緒的ハプティクス。「記録が残った」という重みを感じさせる。
enum Haptics {
    /// 通常の記録保存
    static func success() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    /// 廃車進行中の編成を記録した時の特別な振動
    /// （二回続けて、見送りの重みを出す）
    static func farewell() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        gen.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            gen.impactOccurred(intensity: 0.7)
        }
    }

    /// コンプリート達成（コレクション100%）
    static func celebrate() {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { impact.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { impact.impactOccurred() }
    }

    /// 軽いタップ
    static func tick() {
        let gen = UISelectionFeedbackGenerator()
        gen.selectionChanged()
    }
}
