import Foundation
import StoreKit

/// StoreKit 2 を使った買い切り課金のマネージャ。
/// シンプルな非消費型（NonConsumable）1製品のみを扱う：
/// - `com.ryofujimatsu.tetsulog.pro`（実機/App Store公開時は実プロダクトIDに置換）
///
/// 設計思想:
/// - サーバー不要・サブスクなし・買い切り一度きり（LPの約束）
/// - エンタイトルメントの真実はAppleの`Transaction.currentEntitlements`にのみ依存
/// - UserDefaults へは状態キャッシュのみ（同期前の起動でも体感を遅らせない）
@MainActor
@Observable
final class PurchaseManager {
    /// プロダクトID。本番リリース前に必ず自分のIDへ書き換え。
    static let proProductID = "com.ryofujimatsu.tetsulog.pro"

    /// 状態
    private(set) var product: Product?
    /// 機能解放の唯一の真実。Apple が検証した `Transaction.currentEntitlements` でのみ true になる。
    /// UserDefaults キャッシュからは絶対に true にしない（キャッシュ改ざんで解放されないように）。
    private(set) var isPro: Bool = false
    /// 起動後に一度でもエンタイトルメントを確認したか（UI の「確認中」判定用）。
    private(set) var hasCheckedEntitlements: Bool = false
    private(set) var isPurchasing: Bool = false
    private(set) var lastError: String?

    private let cacheKey = "tetsulog.isPro"
    /// 表示専用の前回検証結果。機能ゲートには使わない（あくまで体感用）。
    var cachedProForDisplay: Bool { UserDefaults.standard.bool(forKey: cacheKey) }

    private nonisolated(unsafe) var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactionUpdates()
        // 起動直後にローカルの検証済みエンタイトルメントを確認する。
        // currentEntitlements は端末内の署名済みレシートを読むためオフラインでも有効。
        Task { await refreshEntitlements() }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - プロダクト取得

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            self.product = products.first
        } catch {
            lastError = "プロダクト情報を取得できませんでした：\(error.localizedDescription)"
        }
        // プロダクト取得の成否に関わらず、エンタイトルメントは常に確認する
        // （ネットワーク不通でプロダクト取得が失敗しても解放状態は端末内で判定できる）。
        await refreshEntitlements()
    }

    // MARK: - 購入

    @discardableResult
    func purchase() async -> Bool {
        guard let product else {
            lastError = "プロダクトが読み込まれていません。"
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try verify(verification)
                await tx.finish()
                await refreshEntitlements()
                Haptics.celebrate()
                return true

            case .userCancelled:
                return false

            case .pending:
                // 親の承認待ち・銀行承認待ち等。完了したら listenForTransactionUpdates で拾われる
                lastError = "購入は保留中です。承認後に有効化されます。"
                return false

            @unknown default:
                lastError = "不明な購入結果です。"
                return false
            }
        } catch {
            lastError = "購入に失敗しました：\(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 復元

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = "購入の復元に失敗しました：\(error.localizedDescription)"
        }
    }

    // MARK: - エンタイトルメントの真実値

    private func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == Self.proProductID,
               tx.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
        hasCheckedEntitlements = true
        // 表示用キャッシュを更新（次回起動の体感用。ゲート判定には使わない）。
        UserDefaults.standard.set(owned, forKey: cacheKey)
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let tx) = update {
                    await tx.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}
