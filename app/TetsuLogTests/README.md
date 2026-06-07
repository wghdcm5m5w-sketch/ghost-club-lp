# TetsuLog ユニットテスト

純粋関数のテスト一式。数学・パース・正規表現のリグレッションを検知する。

## 対象

| ファイル | 何を検証 |
|---|---|
| `FormationNumberParserTests.swift` | 車番(クハE235-1247)・編成記号(トウ47/J36)の抽出、ノイズ除外、重複排除 |
| `SunCalculatorTests.swift` | NOAA太陽位置の合理性（夜は地平線下、夏至正午は高い、夏>冬）、順光/逆光判定 |
| `CSVImporterTests.swift` | CSVパーサ（クォート/改行/エスケープ）、列マッピング推測、日付フォーマット5種 |
| `PolylineCodecTests.swift` | 廃線軌跡のエンコード/デコード往復性 |

## Xcodeで実行する手順

### 自動で取り込む（推奨）
- 上位の `project.yml` に `TetsuLogTests` ターゲットを定義済み。
- Mac で `cd app && xcodegen generate` を実行すると、本テストもターゲットに含まれた状態で `.xcodeproj` が再生成される。

### 既存の .xcodeproj に手動で足す場合
1. Xcode → File → New → Target → **Unit Testing Bundle**
2. Product Name: `TetsuLogTests`、Target to be Tested: `TetsuLog`
3. 生成された雛形を削除し、本フォルダの `.swift` をターゲットに追加（Membership = TetsuLogTests）
4. ⌘U で実行

## 実行コマンド（CIなど）

```bash
xcodebuild test \
  -project app/TetsuLog.xcodeproj \
  -scheme TetsuLog \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 設計方針

- **純粋関数のみテスト**: View・SwiftData・CloudKit・ファイルIOはここでは検証しない（Snapshot/UIテストの領域）。
- **合理性チェック中心**: SunCalculator は厳密値ではなく「夜は地平線下」「夏>冬」等の現実妥当性で検証。アルゴリズムの数式バグは捕捉できる。
- **依存ゼロ**: 外部ライブラリ不使用、XCTestのみ。
