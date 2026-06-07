# TetsuLog 技術設計書 / プロダクト仕様

> 鉄道趣味のすべてを、ひとつのアプリに。
> Apple純正技術だけで作る、完全無料運用・プライバシー第一のガチ鉄向けライフログ。

最終更新: 2026-06-07

---

## 0. 設計の3原則

| 原則 | 意味 | 技術的帰結 |
|---|---|---|
| **完全無料運用** | 開発者の固定費は Apple Developer 年会費(11,800円)のみ | サーバーを持たない。データ保存はユーザーのiCloud。実行時の外部API呼び出しゼロ |
| **プライバシー第一** | 運営者がユーザーデータを見られない設計 | CloudKit **Private** DB のみ。サードパーティSDK・解析ツール一切なし |
| **Apple純正で高品質** | 大手も真似しにくいOS統合体験 | SwiftUI / SwiftData / CloudKit / VisionKit / MapKit / ActivityKit / WidgetKit / App Intents |

「やらないことを決める」のが本プロダクトの肝。SNS・マッチング・走行音共有・リアルタイム在線監視は**意図的に作らない**（運営負荷・サーバー費・権利処理が個人開発と無料運用を破壊するため）。

---

## 1. 技術スタック（確定）

| レイヤー | 採用 | 備考 |
|---|---|---|
| 言語 | Swift 6 | strict concurrency |
| UI | SwiftUI | iOS 18+ ターゲット |
| 永続化 | SwiftData | `@Model` ベース |
| 同期 | CloudKit (Private DB) | SwiftData の `ModelConfiguration(cloudKitDatabase:)` で自動同期 |
| 認証 | Sign in with Apple | iCloudアカウントに紐付くため明示ログインは最小限 |
| OCR | Vision (`RecognizeTextRequest`) / Live Text | 端末内処理 |
| 地図 | MapKit (`Map`, `MapPolyline`) | 乗車区間・撮影地ピン |
| 位置 | CoreLocation | ジオフェンス(`CLMonitor`) |
| 太陽計算 | 自前実装（NOAA算法） | 外部ライブラリ不要 |
| ライブ表示 | ActivityKit | 乗車セッションのLive Activity / Dynamic Island |
| ウィジェット | WidgetKit | ホーム/ロック画面 |
| 音声操作 | App Intents | Siri / ショートカット |
| Watch | WatchConnectivity + 独立Widget | スマートスタック表示 |
| 法務ページ | GitHub Pages | プライバシーポリシー・規約（本リポジトリで配信） |

### 最低ターゲット
- iOS 18.0 / iPadOS 18.0 / watchOS 11.0
- ActivityKit の最新APIと SwiftData+CloudKit の安定性を優先

---

## 2. データモデル（SwiftData）

> CloudKit同期のため全プロパティに **デフォルト値** を持たせ、リレーションは optional にする（CloudKit制約）。

```swift
import SwiftData
import Foundation
import CoreLocation

// 形式マスタ（同梱の静的データ + ユーザー補完）
@Model
final class VehicleClass {
    var id: UUID = UUID()
    var name: String = ""           // 例: "E235系"
    var operatorName: String = ""   // 例: "JR東日本"
    var category: String = ""       // 通勤/特急/新幹線/機関車...
    var lineNames: [String] = []    // 主な運用路線
    var isRetiring: Bool = false    // 廃車進行中フラグ
    var introducedYear: Int? = nil
    var retiredYear: Int? = nil
    var note: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Formation.vehicleClass)
    var formations: [Formation]? = []

    init() {}
}

// 編成（個体）: トウ47編成 など
@Model
final class Formation {
    var id: UUID = UUID()
    var code: String = ""           // 編成番号 "トウ47" / "J36"
    var carNumbers: [String] = []   // ["クハE235-47", ...]
    var carCount: Int = 0
    var depot: String = ""          // 所属
    var isActive: Bool = true
    var vehicleClass: VehicleClass? = nil

    @Relationship(deleteRule: .cascade, inverse: \Sighting.formation)
    var sightings: [Sighting]? = []

    init() {}
}

// 遭遇記録（撮影・目撃）
@Model
final class Sighting {
    var id: UUID = UUID()
    var date: Date = Date.now
    var stationName: String = ""
    var lineName: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var note: String = ""
    var photoFilenames: [String] = []   // CloudKit Asset 連携はファイル名で管理
    var sunAzimuth: Double? = nil       // 撮影時の太陽方位（順光判定キャッシュ）
    var isLastRun: Bool = false         // ラストラン記録
    var formation: Formation? = nil
    var shootingSpot: ShootingSpot? = nil

    init() {}
}

// 乗車記録（区間）
@Model
final class RideSegment {
    var id: UUID = UUID()
    var date: Date = Date.now
    var fromStation: String = ""
    var toStation: String = ""
    var lineName: String = ""
    var distanceKm: Double = 0
    var formationCode: String = ""      // 乗車した編成（任意）
    var durationSec: Int = 0
    var note: String = ""

    init() {}
}

// 撮影地
@Model
final class ShootingSpot {
    var id: UUID = UUID()
    var name: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var bearingToTrack: Double = 0      // 線路（被写体）方向の方位角
    var bestHours: String = ""          // メモ: "午前順光"
    var isPublic: Bool = false          // 将来の共有用フラグ（現状は個人用）
    var note: String = ""

    init() {}
}

// ウォッチリスト（接近アラート対象）
@Model
final class WatchItem {
    var id: UUID = UUID()
    var targetClassName: String = ""    // 形式名 or
    var targetFormationCode: String = "" // 編成番号（任意）
    var enabled: Bool = true
    var createdAt: Date = Date.now

    init() {}
}

// 廃線（静的同梱 + 表示用）
@Model
final class AbandonedLine {
    var id: UUID = UUID()
    var name: String = ""
    var openedYear: Int? = nil
    var closedYear: Int? = nil
    var encodedPolyline: String = ""    // 軌跡（GeoJSON or polyline文字列）
    var note: String = ""

    init() {}
}
```

### CloudKit 設定
```swift
let config = ModelConfiguration(
    "TetsuLog",
    cloudKitDatabase: .private("iCloud.com.yourname.tetsulog")
)
let container = try ModelContainer(
    for: VehicleClass.self, Formation.self, Sighting.self,
        RideSegment.self, ShootingSpot.self, WatchItem.self, AbandonedLine.self,
    configurations: config
)
```

### 同梱マスタデータ
- `VehicleClass` / `Formation` の初期データは JSON で同梱し、初回起動時にシード。
- 廃線データは GeoJSON を bundle 同梱（OpenStreetMap/有志データのライセンスに留意）。
- 駅・ダイヤデータは GTFS（静的）またはODPTの静的データを変換して同梱。
- **写真本体**は SwiftData に格納せず、`Application Support` 配下にファイル保存し、CloudKit Asset として同期。

---

## 3. 画面構成

### タブ構成（v1.0）
```
TabView
├── 図鑑 (Collection)      … 形式別グリッド、収集率、形式・編成のユーザー追加
├── 記録 (Log)             … 遭遇・乗車のタイムライン、編集・削除、検索
├── 地図 (Map)             … 乗車区間ハイライト + 撮影地ピン + 廃線、撮影地→順光計算
├── 統計 (Stats)           … 累計距離 / Top形式・路線・駅 / 月別推移 / ラストラン集計
└── 設定 (Settings)        … 同期状態・データ書き出し/読み込み・ウォッチリスト
```

### 主要画面
| 画面 | 役割 | 主なView |
|---|---|---|
| 図鑑グリッド | 形式ごとの編成コレクション率 | `LazyVGrid` + 進捗リング |
| 形式詳細 | 編成一覧・遭遇履歴・廃車情報 | `List` + ヘッダ |
| 記録入力 | 撮影/乗車をワンシートで追加 | `.sheet` + Form |
| OCRキャプチャ | カメラ/写真から編成番号抽出 | `DataScannerViewController` ラップ |
| タイムライン | 年・月別の自動年表 | `ScrollView` セクション |
| 地図 | 区間・ピン・廃線オーバーレイ | `Map` + `MapPolyline` |
| 撮影地詳細 | 順光計算・ベスト時間 | サン計算View |
| 乗車セッション | Live Activity起動・終了 | ActivityKit制御画面 |

---

## 4. 機能別 実装方針

### 4.1 編成OCR（Feature 02）
- `DataScannerViewController`（VisionKit）でライブテキスト、または静止画は `RecognizeTextRequest`。
- 正規表現で日本の車番/編成番号パターンを抽出：
  - 車番例: `クハE235-1247` → `^[ァ-ヶ]{1,3}[A-Z]?\d{2,4}-\d{1,4}$`
  - 編成記号例: `トウ47`, `J36`, `W1`
- 抽出候補を形式マスタと突き合わせ、上位候補を提示 → ユーザー確定。
- **完全端末内**。ネットワーク不使用。

### 4.2 順光・逆光計算（Feature 04）
- 太陽位置は NOAA Solar Position Algorithm を自前実装（緯度経度＋日時 → 方位角・高度）。
- 判定: `撮影地.bearingToTrack` と 太陽方位角の差分 θ
  - |θ| ≤ 45° → 順光
  - 45° < |θ| ≤ 135° → 斜光
  - |θ| > 135° → 逆光
- 結果は `Sighting.sunAzimuth` にキャッシュ。

```swift
struct SunPosition {
    let azimuth: Double   // 度（北=0, 東=90）
    let altitude: Double  // 度
}
func sunPosition(lat: Double, lon: Double, date: Date) -> SunPosition { /* NOAA */ }

enum LightDirection { case front, side, back }
func lightDirection(trackBearing: Double, sunAzimuth: Double) -> LightDirection {
    let d = abs((trackBearing - sunAzimuth).truncatingRemainder(dividingBy: 360))
    let diff = min(d, 360 - d)
    switch diff {
    case ..<45: return .front
    case ..<135: return .side
    default: return .back
    }
}
```

### 4.3 ライブアクティビティ（Feature 07）
- `ActivityKit` で乗車セッションを表現。
- `ActivityAttributes`：
```swift
struct RideAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var nextStation: String
        var elapsedSec: Int
        var distanceKm: Double
        var progress: Double      // 0...1 区間内進捗
    }
    var formationCode: String
    var lineName: String
}
```
- 更新は端末内タイマー＋（任意で）CoreLocationの区間進捗から `Activity.update(...)`。
- 外部プッシュ（APNs）は**使わない**（サーバー不要・無料維持）。ローカル更新のみ。
- Dynamic Island の compact/expanded/minimal を実装。

### 4.4 接近アラート（Feature 08）— 無料で成立させる設計
> ⚠️ リアルタイム在線データは扱わない。GPS×静的ダイヤ×ウォッチリストの**端末内予測**。

仕組み：
1. ユーザーが `WatchItem`（形式/編成）を登録。
2. 同梱の静的ダイヤ（GTFS）から、その形式が運用される路線・通過時間帯を端末内で算出。
3. `CLMonitor`（iOS 17+）で登録撮影地・主要駅にジオフェンスを設定。
4. ジオフェンス進入 × 現在時刻がダイヤの「通過しそうな窓」に合致 → ローカル通知。
5. 通知文は確率的表現に統一（「来るかも」）。確実性は保証しない旨をUIに明記。

```swift
// ジオフェンス監視
let monitor = await CLMonitor("tetsulog.geofence")
await monitor.add(
    CLMonitor.CircularGeographicCondition(center: spot.coordinate, radius: 800),
    identifier: spot.id.uuidString
)
// 進入イベント → ダイヤ窓と照合 → UNUserNotificationCenter で通知
```

- 位置情報は端末外に一切出さない。サーバー照会なし。

### 4.5 CloudKit同期
- SwiftData + `.private` CloudKit で自動。ユーザー操作は基本不要。
- 設定画面に同期ステータス・最終同期時刻・「iCloudにのみ保存」の明示文言。
- コンフリクトは last-writer-wins（SwiftDataデフォルト）で許容。

### 4.6 OS統合
| 機能 | API | 内容 |
|---|---|---|
| ウィジェット | WidgetKit | 今月の遭遇数 / 最近の編成 / 収集率 |
| ロック画面ウィジェット | WidgetKit (accessory) | お気に入り編成の最終遭遇日 |
| Spotlight | CoreSpotlight | 編成番号・形式で過去記録を検索 |
| Siri | App Intents | 「◯◯系を記録」「乗車を開始」 |
| 共有シート | Share Extension | 写真Appから直接記録追加 |
| Watch | 独立Widget + WCSession | スマートスタックに乗車Live |

---

## 5. 開発ロードマップ

| Ver | 期間目安 | スコープ | 完了条件 |
|---|---|---|---|
| **v1.0 (MVP)** | 〜2ヶ月 | データモデル / 図鑑 / 記録入力 / タイムライン / 地図 / CloudKit同期 | 自分で日常使いでき、App Store審査通過 |
| **v1.1** | +1ヶ月 | OCR(Live Text) / ウィジェット / Spotlight / 共有シート | 撮影→自動記録が成立 |
| **v1.2** | +1ヶ月 | 順光計算 / 廃線オーバーレイ / Siri / ライブアクティビティ | 差別化機能が出揃う |
| **v1.3** | +0.5ヶ月 | 接近アラート / Apple Watch / 多言語(en/zh/ko) | 完成形 |

各バージョンで TestFlight → App Store の順に配布。

---

## 6. マネタイズ

- **買い切り 980円**（StoreKit 2、Non-Consumable）。
- 無料層：基本記録（図鑑/記録/地図）。
- 有料解放：OCR・順光計算・廃線データ・ライブアクティビティ・接近アラート・無制限写真。
- サブスクなし・広告なし・追跡なしを訴求点として明記。
- 家族共有（Family Sharing）対応。

```swift
// StoreKit 2 概略
let products = try await Product.products(for: ["com.yourname.tetsulog.pro"])
let result = try await products.first?.purchase()
// .success → エンタイトルメント保存（端末内）
```

---

## 7. App Store 提出チェックリスト

- [ ] プライバシーポリシー / 利用規約 / 特商法表記（GitHub Pagesで配信、本リポジトリに用意済み）
- [ ] App Privacy「データを収集しません」を正確に申告（実際に収集しない設計）
- [ ] 位置情報の用途文言（Info.plist `NSLocationWhenInUseUsageDescription`）を接近アラート用に明記
- [ ] カメラ用途文言（OCR）
- [ ] ライブアクティビティ・プッシュ未使用の確認
- [ ] スクリーンショット（6.7" / 6.1" / iPad 12.9"）
- [ ] サポート連絡先（メール）
- [ ] 著作権・データライセンス（廃線GeoJSON, GTFS, 形式データの出典明記）

---

## 8. 法務・データ出典の注意

| データ | 出典候補 | ライセンス対応 |
|---|---|---|
| 駅・路線・ダイヤ（静的） | GTFS / ODPT静的データ | 利用規約を確認、再配布条件を順守 |
| 廃線軌跡 | OpenStreetMap / 有志データ | ODbL等のクレジット表記 |
| 形式・編成マスタ | 自作 + 公開資料 | 事実情報の集約。画像は同梱しない |
| 車両画像 | **同梱しない**（ユーザー撮影のみ） | 権利リスク回避 |

> 走行音・他者撮影写真・リアルタイム在線は**扱わない**ことで権利リスクとサーバー費を回避する。

---

## 9. 意図的に「作らない」もの

- ユーザー間SNS・コメント・マッチング（モデレーション負荷）
- 走行音アップロード・共有（JASRAC等の権利処理）
- リアルタイム在線監視・全国列車位置（サーバー必須・公式API非公開）
- ライブカメラ統合（配信契約）
- 広告・行動解析SDK（プライバシー方針と矛盾）

これらは「鉄道趣味OS」構想の将来拡張ではあるが、**無料運用・個人開発・プライバシー第一**の3制約下では着手しない。

---

## 10. 次のアクション

1. Xcodeプロジェクト雛形作成（SwiftData+CloudKit有効化、ターゲット設定）
2. データモデルの実装とシードJSON整備
3. v1.0 の4タブUI骨格
4. CloudKit同期の実機検証（2端末）
5. TestFlight 内部配布
