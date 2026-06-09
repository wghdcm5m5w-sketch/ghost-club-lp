import SwiftUI
import LocalAuthentication

/// アプリロック（Face ID / Touch ID / 端末パスコード）。
/// 遭遇記録・写真・録音は本人だけのもの、という約束を端末レベルで守る。
/// 認証は LocalAuthentication に完全委任し、アプリは結果のみを受け取る。
/// 生体情報そのものにアプリが触れることは一切ない。
@MainActor
@Observable
final class AppLockManager {
    /// 設定トグルと TetsuLogApp が共有する UserDefaults キー
    static let enabledKey = "tetsulog.appLockEnabled"
    /// 再ロックまでの猶予秒数（0=すぐに / 60 / 300）
    static let graceKey = "tetsulog.appLockGraceSec"

    private(set) var isUnlocked = false
    private(set) var isAuthenticating = false
    private(set) var lastError: String?

    /// バックグラウンド移行時刻（猶予判定用・メモリ内のみ。
    /// プロセスが死ねば次回起動は必ずロックから始まる）
    private var backgroundedAt: Date?

    /// この端末で認証手段（生体 or パスコード）が使えるか
    nonisolated static var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// バックグラウンド移行時に呼ぶ。次回前面化で再認証を要求する。
    func lock() {
        isUnlocked = false
    }

    /// バックグラウンド移行を記録する（猶予判定の起点）。
    func noteBackgrounded() {
        backgroundedAt = .now
    }

    /// 前面復帰時に呼ぶ。猶予時間を超えていれば施錠する。
    /// 短いアプリ切替のたびに Face ID を要求しないための仕組み。
    func relockIfNeeded(grace: TimeInterval) {
        guard isUnlocked, let at = backgroundedAt else { return }
        backgroundedAt = nil
        if Date.now.timeIntervalSince(at) >= grace {
            isUnlocked = false
        }
    }

    func unlock() async {
        guard !isAuthenticating, !isUnlocked else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedCancelTitle = "キャンセル"
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "記録を表示するためにロックを解除します"
            )
            if success {
                isUnlocked = true
                lastError = nil
            }
        } catch {
            lastError = "認証できませんでした。もう一度お試しください。"
        }
    }
}

/// ロック画面。国鉄レトロの意匠のまま「改札」を表現する。
struct LockScreenView: View {
    let manager: AppLockManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            NavyBackground()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Palette.gold)
                VStack(spacing: 8) {
                    Text("TetsuLog はロック中")
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                        .foregroundStyle(Theme.Palette.cream)
                    Text("あなたの記録はこの端末の認証で守られています")
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.Palette.creamSub)
                        .multilineTextAlignment(.center)
                }
                if let message = manager.lastError {
                    Text(message)
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.Palette.redLight)
                        .multilineTextAlignment(.center)
                }
                Button {
                    Task { await manager.unlock() }
                } label: {
                    Label("ロックを解除", systemImage: "faceid")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.Palette.red))
                        .foregroundStyle(Theme.Palette.paper)
                }
                .buttonStyle(.plain)
                .disabled(manager.isAuthenticating)
                Spacer()
                Spacer()
            }
            .padding(32)
        }
        // コールドスタート時のみ自動で認証を出す。
        // バックグラウンド中の挿入時は前面復帰側（TetsuLogApp）が発火する。
        .task {
            if scenePhase == .active {
                await manager.unlock()
            }
        }
    }
}

/// アプリスイッチャーのスナップショットに記録内容が写らないようにする目隠し。
/// ロック設定が有効なとき、非アクティブ化の瞬間に被せる。
struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            NavyBackground()
            Image(systemName: "tram.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Palette.gold)
        }
    }
}
