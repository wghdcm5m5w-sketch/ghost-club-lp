import SwiftUI
import SwiftData

@main
struct TetsuLogApp: App {
    let container: ModelContainer

    init() {
        let types: [any PersistentModel.Type] = [
            VehicleClass.self, Formation.self, Sighting.self,
            RideSegment.self, ShootingSpot.self, WatchItem.self, AbandonedLine.self
        ]

        // 1) App Group + CloudKit の共有ストア（ウィジェット連携・本番構成）
        if let shared = SharedStore.container {
            container = shared
            // App Group は開けたが CloudKit が使えずローカル共有に落ちた場合は同期されない。
            StorageStatus.current = (SharedStore.mode == .cloudKitShared) ? .cloudShared : .localOnly
            return
        }

        // 2) CloudKit 名前付きストア（App Group 未設定だが iCloud は使える構成）
        do {
            let config = ModelConfiguration(
                "TetsuLog",
                cloudKitDatabase: .private("iCloud.com.ryofujimatsu.tetsulog")
            )
            container = try ModelContainer(for: Schema(types), configurations: config)
            StorageStatus.current = .cloudNamed
            return
        } catch {
            // iCloud/CloudKit のエンタイトルメントが無い等で失敗 → ローカルのみで続行
            print("CloudKit ストア初期化に失敗、ローカルにフォールバック: \(error)")
        }

        // 3) ローカルのみ（無料アカウント・最小構成での実機確認用。同期はされない）
        do {
            let local = ModelConfiguration("TetsuLogLocal", cloudKitDatabase: .none)
            container = try ModelContainer(for: Schema(types), configurations: local)
            StorageStatus.current = .localOnly
        } catch {
            fatalError("ModelContainer の初期化に失敗: \(error)")
        }
    }

    @State private var rideManager = RideManager()
    @State private var purchaseManager = PurchaseManager()
    @State private var appLock = AppLockManager()
    @AppStorage("tetsulog.onboardingDone") private var onboardingDone = false
    @AppStorage(AppLockManager.enabledKey) private var appLockEnabled = false
    @AppStorage(AppLockManager.graceKey) private var appLockGraceSec = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if onboardingDone {
                        RootTabView()
                            .environment(rideManager)
                            .environment(purchaseManager)
                    } else {
                        OnboardingView()
                    }
                }

                // アプリロック有効時：未認証なら全面を改札でふさぐ
                if appLockEnabled && !appLock.isUnlocked {
                    LockScreenView(manager: appLock)
                        .zIndex(1)
                }

                // アプリスイッチャーのスナップショットに記録を写さない目隠し
                if appLockEnabled && appLock.isUnlocked && scenePhase != .active {
                    PrivacyShieldView()
                        .zIndex(2)
                }
            }
            .task {
                await SeedData.seedIfNeeded(container.mainContext)
                await purchaseManager.loadProducts()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard appLockEnabled else { return }
                switch newPhase {
                case .background:
                    // 即時施錠ではなく移行時刻を記録（猶予はユーザー設定）。
                    // 背面中の見た目は PrivacyShieldView が覆う。
                    appLock.noteBackgrounded()
                case .active:
                    appLock.relockIfNeeded(grace: TimeInterval(appLockGraceSec))
                    if !appLock.isUnlocked {
                        Task { await appLock.unlock() }
                    }
                default:
                    break
                }
            }
        }
        .modelContainer(container)
    }
}
