# 2ステップ抽出方式（分割推定方式）実装仕様書

## ドキュメント情報

- **作成日**: 2025-10-22
- **最終更新**: 2025-10-22
- **バージョン**: 1.2
- **対象リリース**: iOS 26+, macOS 26+

---

## 目次

1. [概要](#概要)
2. [アーキテクチャ](#アーキテクチャ)
3. [実装仕様](#実装仕様)
4. [データ構造](#データ構造)
5. [プロンプトテンプレート](#プロンプトテンプレート)
6. [マッピングルール](#マッピングルール)
7. [ログフォーマット](#ログフォーマット)
8. [現在の実装状況](#現在の実装状況)
9. [今後のスケジュール](#今後のスケジュール)

---

## 概要

### 背景

従来の単純推定方式では、すべてのアカウント情報を一度のAI推論で抽出しようとするため、以下の課題がありました：

- 複雑なドキュメントでは抽出精度が低下
- カテゴリごとの最適なプロンプトが使えない
- 抽出すべきフィールドの選択が不適切

### 目的

2ステップ抽出方式（分割推定方式）は、ドキュメントのカテゴリ判定と情報抽出を分離することで、以下を実現します：

1. **精度向上**: カテゴリに特化したプロンプトで抽出精度を向上
2. **柔軟性**: 各カテゴリに最適なフィールド定義
3. **トレーサビリティ**: カテゴリ判定結果を明示的に記録

### 基本方針

```
Step 1: カテゴリ判定（2層構造）
  ├─ Step 1a: メインカテゴリ判定（5分類）
  └─ Step 1b: サブカテゴリ判定（各5分類、計25分類）

Step 2: アカウント情報抽出
  └─ サブカテゴリ別の専用構造体による抽出
```

---

## アーキテクチャ

### システム構成図

```
┌─────────────────────────────────────────────────────────┐
│                    UnifiedExtractor                      │
│  (統一抽出フロー - useTwoSteps=true で2ステップ有効)     │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│                  TwoStepsProcessor                       │
│             (2ステップ抽出のコア処理)                     │
└─────┬────────────────────────────────────────┬──────────┘
      │                                        │
      │ Step 1                                 │ Step 2
      ▼                                        ▼
┌──────────────────┐              ┌────────────────────────┐
│ analyzeDocument  │              │ extractAccountInfo     │
│     Type()       │              │     BySteps()          │
└────┬─────────────┘              └────────┬───────────────┘
     │                                     │
     ├─ Step 1a ────────────┐             │
     │  メインカテゴリ判定    │             │
     │  (5分類)             │             │
     │                      │             │
     └─ Step 1b ────────────┤             │
        サブカテゴリ判定     │             │
        (25分類)            │             │
                            │             │
                            ▼             ▼
                     ┌──────────────────────────┐
                     │     ContentInfo          │
                     │  - mainCategory          │
                     │  - subCategory           │
                     │  - has* フラグ群          │
                     └────────┬─────────────────┘
                              │
                              ▼
                     ┌──────────────────────────┐
                     │  SubCategoryConverter    │
                     │  (マッピングルール適用)    │
                     └────────┬─────────────────┘
                              │
                              ▼
                     ┌──────────────────────────┐
                     │     AccountInfo          │
                     │  (統一フォーマット)        │
                     └──────────────────────────┘
```

### クラス関連図

```
┌─────────────────────┐
│  UnifiedExtractor   │
│  - extract()        │
└──────┬──────────────┘
       │ 使用
       ▼
┌─────────────────────┐
│ TwoStepsProcessor   │
│ - analyzeDocument   │
│   Type()            │
│ - extractAccount    │
│   InfoBySteps()     │
└──────┬──────────────┘
       │ 使用
       ▼
┌──────────────────────┐
│ FoundationModels     │
│   Extractor          │
│ - extractMainCategory│
│   Info()             │
│ - extractSubCategory │
│   Info()             │
│ - extractAndConvert()│
└──────────────────────┘
       │ 使用
       ▼
┌──────────────────────┐
│ SubCategoryConverter │
│ - convert()          │
└──────┬───────────────┘
       │ 使用
       ▼
┌──────────────────────┐
│  MappingRuleLoader   │
│ - loadRule()         │
└──────────────────────┘
```

---

## 実装仕様

### Step 1a: メインカテゴリ判定

#### 処理フロー

1. テストデータを読み込み
2. メインカテゴリ判定プロンプトテンプレートを読み込み
   - `step1a_main_category_{language}.txt`
3. プロンプトにテストデータを埋め込み
4. FoundationModels APIで推論実行（JSON形式）
5. `MainCategoryInfo`を抽出

#### カテゴリ定義（5分類）

| カテゴリ | rawValue | 説明 | 例 |
|---------|----------|------|-----|
| 個人生活 | personal | 自宅、教育、医療、連絡先 | 自宅住所、習い事、病院 |
| 金融・決済 | financial | 銀行、カード、決済、保険、仮想通貨 | 銀行口座、クレカ |
| デジタルサービス | digital | サブスク、AI、SNS、EC、アプリ | Netflix、ChatGPT |
| 仕事・ビジネス | work | サーバー、SaaS、開発ツール | AWS EC2、Slack |
| インフラ・公的 | infrastructure | 通信、公共料金、行政、免許 | docomo、マイナポータル |

#### データ構造

```swift
@Generable(description: "メインカテゴリ判定結果")
public struct MainCategoryInfo: Codable {
    @Guide(description: "メインカテゴリ（personal, financial, digital, work, infrastructure のいずれか1つ）")
    public var mainCategory: String

    public var mainCategoryEnum: MainCategory { get }  // 計算プロパティでenum取得
}
```

#### 実装クラス

- **ファイル**: `TwoStepsProcessor.swift`
- **メソッド**: `analyzeDocumentType()` → Step 1a部分
- **内部呼び出し**: `FoundationModelsExtractor.extractMainCategoryInfo()`

---

### Step 1b: サブカテゴリ判定

#### 処理フロー

1. Step 1aで判定されたメインカテゴリに対応するプロンプトを読み込み
   - `step1b_{mainCategory}_{language}.txt`
2. プロンプトにテストデータを埋め込み
3. FoundationModels APIで推論実行（JSON形式）
4. `SubCategoryInfo`を抽出

#### サブカテゴリ定義（25分類）

各メインカテゴリに5つのサブカテゴリを定義：

**personal（個人生活）**
- personalHome: 自宅・公共料金
- personalEducation: 学校・習い事
- personalHealth: 病院・医療
- personalContacts: 連絡先・知人
- personalOther: その他個人

**financial（金融・決済）**
- financialBanking: 銀行・証券
- financialCreditCard: クレジットカード
- financialPayment: 決済サービス
- financialInsurance: 保険・年金
- financialCrypto: 仮想通貨

**digital（デジタルサービス）**
- digitalSubscription: サブスク
- digitalAI: AIサービス
- digitalSocial: SNS
- digitalShopping: EC・ショッピング
- digitalApps: アプリ・ゲーム

**work（仕事・ビジネス）**
- workServer: サーバー・VPS
- workSaaS: 業務SaaS
- workDevelopment: 開発ツール
- workCommunication: ビジネスコミュニケーション
- workOther: その他業務

**infrastructure（インフラ・公的）**
- infraTelecom: 携帯・通信
- infraUtilities: 公共料金
- infraGovernment: 行政サービス
- infraLicense: 免許・資格
- infraTransportation: 交通・移動

#### データ構造

```swift
@Generable(description: "サブカテゴリ判定結果")
public struct SubCategoryInfo: Codable {
    @Guide(description: "サブカテゴリ（メインカテゴリに応じた5つの選択肢から1つ）")
    public var subCategory: String

    public var subCategoryEnum: SubCategory? { get }  // 計算プロパティでenum取得
}

public struct ContentInfo: Codable {
    public var mainCategory: String
    public var subCategory: String

    public var mainCategoryEnum: MainCategory { get }
    public var subCategoryEnum: SubCategory? { get }
}
```

**設計原則**:
- MainCategoryInfo/SubCategoryInfoは@Generableマクロを使用してFoundationModelsの構造化出力機能を活用
- confidenceフィールドは削除（AIの自己評価は信頼性が低いため不要）
- has*フィールドも削除（サブカテゴリごとの専用構造体とマッピングルールから直接AccountInfoを構築するため不要）
- プロンプトでは出力形式を指定しない（FoundationModelsとGenerableマクロが適切に処理）

#### 実装クラス

- **ファイル**: `TwoStepsProcessor.swift`
- **メソッド**: `analyzeDocumentType()` → Step 1b部分
- **内部呼び出し**: `FoundationModelsExtractor.extractSubCategoryInfo()`

---

### Step 2: アカウント情報抽出

#### 処理フロー

1. Step 1で判定されたサブカテゴリに対応する専用構造体を選択
2. サブカテゴリ専用プロンプトテンプレートを読み込み
   - `step2_{language}_generable.txt`（将来的にはサブカテゴリ別に分離予定）
3. プロンプトにテストデータと構造体定義を埋め込み
4. FoundationModels APIで推論実行（@Generable形式）
5. サブカテゴリ専用構造体を抽出（例: `WorkServerInfo`）
6. `SubCategoryConverter`でマッピングルールを適用
7. 統一フォーマット `AccountInfo` に変換

#### サブカテゴリ専用構造体

各サブカテゴリに対応する25個の`@Generable`構造体を定義：

**例: WorkServerInfo**
```swift
@Generable(description: "サーバー・VPS・クラウドに関する情報")
public struct WorkServerInfo: Codable, Equatable, Sendable {
    @Guide(description: "サービス名・タイトル")
    public var title: String?

    @Guide(description: "ユーザー名・アカウント名")
    public var username: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "ホスト名・IPアドレス")
    public var host: String?

    @Guide(description: "ポート番号")
    public var port: Int?

    @Guide(description: "SSH鍵・認証鍵")
    public var sshKey: String?

    @Guide(description: "URL・管理画面")
    public var url: String?

    @Guide(description: "備考・補足情報")
    public var note: String?
}
```

#### マッピングルールの適用

各サブカテゴリ専用構造体から統一フォーマット `AccountInfo` への変換ルールをJSONで定義：

**例: workServer_mapping.json**
```json
{
  "subCategory": "workServer",
  "directMapping": {
    "title": "title",
    "username": "userID",
    "password": "password",
    "host": "host",
    "port": "port",
    "url": "url"
  },
  "noteAppendMapping": {
    "sshKey": "SSH鍵"
  }
}
```

#### 実装クラス

- **ファイル**: `TwoStepsProcessor.swift`
- **メソッド**: `extractAccountInfoBySteps()`
- **内部呼び出し**:
  - `FoundationModelsExtractor.extractAndConvert()`
  - `SubCategoryConverter.convert()`
  - `MappingRuleLoader.loadRule()`

---

## データ構造

### ContentInfo（カテゴリ判定結果）

```swift
@available(iOS 26.0, macOS 26.0, *)
public struct ContentInfo: Codable, Equatable, Sendable {
    public var mainCategoryString: String
    public var subCategoryString: String
    public var confidence: Double?

    public var mainCategory: MainCategory { get }
    public var subCategory: SubCategory? { get }
}
```

**設計原則**: 分割推定方式では、サブカテゴリを判定すれば、そのサブカテゴリ専用構造体（例: `WorkServerInfo`）で情報を抽出し、マッピングルールで`AccountInfo`に変換します。そのため、どの種類の情報が含まれているかを事前判定する`has*`フラグは不要です。

### SubCategory専用構造体（25種類）

全25個のサブカテゴリに対応する構造体を定義：

- **ファイル**: `SubCategoryExtractionStructs.swift`
- **定義数**: 25構造体
- **特徴**: 各サブカテゴリに最適化されたフィールド定義

**実装済み構造体一覧**:
- Personal: PersonalHomeInfo, PersonalEducationInfo, PersonalHealthInfo, PersonalContactsInfo, PersonalOtherInfo
- Financial: FinancialBankingInfo, FinancialCreditCardInfo, FinancialPaymentInfo, FinancialInsuranceInfo, FinancialCryptoInfo
- Digital: DigitalSubscriptionInfo, DigitalAIInfo, DigitalSocialInfo, DigitalShoppingInfo, DigitalAppsInfo
- Work: WorkServerInfo, WorkSaaSInfo, WorkDevelopmentInfo, WorkCommunicationInfo, WorkOtherInfo
- Infrastructure: InfraTelecomInfo, InfraUtilitiesInfo, InfraGovernmentInfo, InfraLicenseInfo, InfraTransportationInfo

### MappingRule（変換ルール）

```swift
@available(iOS 26.0, macOS 26.0, *)
public struct MappingRule: Codable {
    public let subCategory: String
    public let directMapping: [String: String]
    public let noteAppendMapping: [String: String]?
    public let customRules: [String: String]?
}
```

---

## プロンプトテンプレート

### 配置場所

`Sources/AITest/Prompts/`

### テンプレート一覧

#### Step 1a: メインカテゴリ判定（2ファイル）

- `step1a_main_category_ja.txt`: 日本語版
- `step1a_main_category_en.txt`: 英語版

#### Step 1b: サブカテゴリ判定（10ファイル）

各メインカテゴリ × 言語：
- `step1b_personal_ja.txt` / `step1b_personal_en.txt`
- `step1b_financial_ja.txt` / `step1b_financial_en.txt`
- `step1b_digital_ja.txt` / `step1b_digital_en.txt`
- `step1b_work_ja.txt` / `step1b_work_en.txt`
- `step1b_infrastructure_ja.txt` / `step1b_infrastructure_en.txt`

#### Step 2: アカウント情報抽出（2ファイル）

- `step2_ja_generable.txt`: 日本語版
- `step2_en_generable.txt`: 英語版

**注意**: 現在は統一テンプレートですが、将来的にはサブカテゴリ別に分離予定

### プロンプト設計原則

1. **出力形式の指定は不要**: FoundationModelsとGenerableマクロが構造化出力を自動処理するため、JSON形式などの明示的な指示は不要
2. **単一の値を選択**: 複数の値を「|」で区切らない
3. **confidenceは不要**: AI自己評価の信頼性が低いため使用しない
4. **例示の明確化**: 各カテゴリの具体例を豊富に提示
5. **@Generableマクロ活用**: MainCategoryInfo/SubCategoryInfoは@Generableマクロで構造化出力を実現

---

## マッピングルール

### 配置場所

`Sources/AITest/Mappings/`

### ルールファイル（25ファイル）

各サブカテゴリに対応：
- `personalHome_mapping.json`
- `personalEducation_mapping.json`
- ...（全25ファイル）

### ルールフォーマット

```json
{
  "subCategory": "サブカテゴリ名",
  "directMapping": {
    "ソースフィールド名": "AccountInfoフィールド名"
  },
  "noteAppendMapping": {
    "ソースフィールド名": "日本語ラベル"
  },
  "customRules": {
    "特殊ルール名": "処理内容"
  }
}
```

### マッピングの優先順位

1. **directMapping**: 直接フィールドにマッピング
2. **noteAppendMapping**: note フィールドに「ラベル: 値」形式で追加
3. **customRules**: カスタム変換処理（将来の拡張用）

### ルール読み込み

- **クラス**: `MappingRuleLoader`
- **キャッシュ**: 初回読み込み後はメモリキャッシュ
- **エラー処理**: ファイルが見つからない場合は `fatalError`

---

## ログフォーマット

### 構造化ログ（JSON）

2ステップ方式の実行結果は以下のフォーマットで出力：

```json
{
  "pattern": "Chat",
  "level": 1,
  "iteration": 1,
  "method": "generable",
  "language": "ja",
  "experiment_pattern": "abs_gen",
  "request_content": null,
  "expected_fields": [...],
  "unexpected_fields": [...],
  "two_steps_category": {
    "main_category": "work",
    "main_category_display": "仕事・ビジネス",
    "sub_category": "workServer",
    "sub_category_display": "サーバー・VPS"
  }
}
```

### two_steps_category フィールド

| フィールド | 型 | 説明 |
|-----------|-----|------|
| main_category | String | メインカテゴリ（文字列形式） |
| main_category_display | String | メインカテゴリ（日本語表示名） |
| sub_category | String | サブカテゴリ（文字列形式） |
| sub_category_display | String | サブカテゴリ（日本語表示名） |

### メトリクス（TwoStepsExtractionMetrics）

```json
{
  "step1Time": 2.5,
  "step2Time": 1.8,
  "totalTime": 4.3,
  "detectedCategory": "work/workServer",
  "extractedInfoTypes": 4,
  "strategyEffectiveness": 0.8,
  "baseMetrics": {...}
}
```

**注意**: confidenceフィールド（step1Confidence, step2Confidence, overallConfidence）は削除されました。

---

## 現在の実装状況

### ✅ 完了済み

#### アーキテクチャ・設計
- [x] 2ステップ抽出方式の基本設計
- [x] 5×5のカテゴリ階層構造の定義
- [x] 25個のサブカテゴリ専用構造体の設計

#### Step 1: カテゴリ判定
- [x] Step 1a: メインカテゴリ判定の実装
- [x] Step 1b: サブカテゴリ判定の実装
- [x] MainCategory / SubCategory enumの定義
- [x] MainCategoryInfo / SubCategoryInfo構造体の実装
- [x] ContentInfo構造体の実装
- [x] プロンプトテンプレート（16ファイル）
  - [x] step1a × 2言語
  - [x] step1b × 5カテゴリ × 2言語
  - [x] step2 × 2言語

#### Step 2: アカウント情報抽出
- [x] 25個のサブカテゴリ専用構造体の実装（`SubCategoryExtractionStructs.swift`）
- [x] SubCategoryConverterの基本実装
- [x] MappingRuleLoaderの実装
- [x] 25個のマッピングルールファイル（JSON）
- [x] extractAndConvert()メソッドの実装

#### 統合・ログ出力
- [x] UnifiedExtractorへの統合
- [x] TwoStepsProcessorの実装
- [x] 構造化ログへのカテゴリ情報追加
- [x] TwoStepsExtractionMetricsの定義

#### テスト・検証
- [x] level1/chat/generable/ja の最小テスト実行成功
- [x] メインカテゴリ判定の動作確認（work: 0.9）
- [x] サブカテゴリ判定の動作確認（workServer: 0.9）
- [x] マッピングルール読み込みの動作確認
- [x] ログ出力の動作確認

### ⚠️ 一部実装・要改善

#### プロンプト改善
- [⚠️] Step 2のプロンプトはサブカテゴリ別に分離されていない（現在は統一テンプレート）
- [⚠️] AIが複数の値を返す問題（一部プロンプトで発生）
- [⚠️] JSON以外のマークダウン記法を出力する問題（一部改善済み）

#### 抽出精度
- [⚠️] Step 2で実際のフィールドが抽出されていない（テストで全てmissing）
- [⚠️] WorkServerInfo等の構造体からのフィールド抽出ロジックの検証不足
- [⚠️] マッピングルールの実際の動作検証が不十分

### ❌ 未実装

#### 実験・評価
- [ ] 2ステップ方式の本格的な実験実行
- [ ] 単純推定方式との精度比較実験
- [ ] 各サブカテゴリでの動作検証
- [ ] pending項目の検証・評価ワークフロー

#### 機能拡張
- [ ] サブカテゴリ別のStep 2プロンプトテンプレート（25×2=50ファイル）
- [ ] カスタム変換ルール（customRules）の実装
- [ ] 外部LLMでの2ステップ抽出対応
- [ ] JSON形式での2ステップ抽出（現在はGenerableのみ）

#### レポート・可視化
- [ ] 2ステップ方式専用のHTMLレポートフォーマット
- [ ] カテゴリ判定精度の可視化
- [ ] サブカテゴリ別の精度グラフ

---

## 今後のスケジュール

### フェーズ1: 基本機能の完成（優先度: 高）

**目標**: 2ステップ抽出が正しく動作し、実用レベルの精度を達成

#### 1-1. Step 2のフィールド抽出問題の解決（1-2日）
- [ ] WorkServerInfo等からの実際のフィールド抽出を検証
- [ ] マッピングルールの適用ロジックをデバッグ
- [ ] 最低1つのサブカテゴリで完全動作を確認

**成功基準**: `workServer`カテゴリで`title`, `userID`, `password`が正しく抽出される

#### 1-2. プロンプト品質の向上（2-3日）
- [ ] すべてのstep1a/step1bプロンプトを検証・改善
- [ ] AIが単一の値のみを返すことを保証
- [ ] JSON形式のみを出力することを保証
- [ ] 日本語・英語両方のプロンプトを最適化

**成功基準**: 10回実行して9回以上、正しいJSON形式で単一の値が返る

#### 1-3. 基本的な実験実行（1-2日）
- [ ] chat/level1での全サブカテゴリ検証
- [ ] 最低3つのサブカテゴリで動作確認
- [ ] 構造化ログの出力確認

**成功基準**: 3つのサブカテゴリで80%以上の精度

**フェーズ1完了予定**: 2025-10-27

---

### フェーズ2: 実験・評価の本格化（優先度: 中）

**目標**: 全25サブカテゴリでの動作検証と精度評価

#### 2-1. 全サブカテゴリの動作検証（3-5日）
- [ ] 25個のサブカテゴリすべてで最小テスト実行
- [ ] 各サブカテゴリのマッピングルールを検証・調整
- [ ] エラーが発生するサブカテゴリを特定・修正

**成功基準**: 25個すべてのサブカテゴリでエラーなく実行完了

#### 2-2. テストデータの拡充（2-3日）
- [ ] 各サブカテゴリ用のテストケースを追加
- [ ] level2/level3のテストデータ作成
- [ ] 多様なドキュメント形式に対応

**成功基準**: 各サブカテゴリに最低3つのテストケース

#### 2-3. 精度評価実験（3-5日）
- [ ] 単純推定 vs 2ステップ抽出の比較実験
- [ ] サブカテゴリ別の精度レポート作成
- [ ] pending項目の検証ワークフロー確立

**成功基準**: 2ステップ方式が単純推定を10%以上上回る

**フェーズ2完了予定**: 2025-11-05

---

### フェーズ3: プロンプト最適化（優先度: 中）

**目標**: サブカテゴリ別の専用プロンプトで精度をさらに向上

#### 3-1. Step 2のサブカテゴリ別プロンプト作成（5-7日）
- [ ] 25個のサブカテゴリ用にstep2プロンプトを作成
- [ ] 日本語・英語両方（25×2=50ファイル）
- [ ] 各サブカテゴリに最適化された指示内容

**成功基準**: 50個のstep2プロンプトファイルが完成

#### 3-2. アルゴリズム別プロンプト実験（3-5日）
- [ ] 抽象指示（abs）の最適化
- [ ] 厳格指示（strict）の実装
- [ ] 人格指示（persona）の実装
- [ ] 例示（-ex）バリエーションの作成

**成功基準**: 各アルゴリズムで精度5%以上向上

**フェーズ3完了予定**: 2025-11-15

---

### フェーズ4: 機能拡張（優先度: 低）

**目標**: より高度な機能と柔軟性の提供

#### 4-1. 外部LLM対応（3-5日）
- [ ] ExternalLLMExtractorで2ステップ抽出対応
- [ ] JSON形式での2ステップ抽出実装
- [ ] FoundationModels vs 外部LLMの比較実験

**成功基準**: 外部LLMでも同等の精度を達成

#### 4-2. カスタム変換ルール（2-3日）
- [ ] MappingRuleのcustomRulesを実装
- [ ] 複雑な変換ロジックをサポート
- [ ] 条件分岐・計算処理の実装

**成功基準**: customRulesで3種類以上の変換パターンをサポート

#### 4-3. レポート・可視化（3-5日）
- [ ] 2ステップ専用のHTMLレポートテンプレート
- [ ] カテゴリ判定精度のグラフ表示
- [ ] サブカテゴリ別の詳細分析ビュー

**成功基準**: 視覚的に分かりやすいレポートが生成される

**フェーズ4完了予定**: 2025-11-25

---

### フェーズ5: 本番運用準備（優先度: 低）

**目標**: プロダクションレベルの品質と信頼性

#### 5-1. エラーハンドリングの強化（2-3日）
- [ ] 各ステップでの詳細なエラーメッセージ
- [ ] リトライ・フォールバック機構
- [ ] ログレベルの最適化

#### 5-2. パフォーマンス最適化（2-3日）
- [ ] キャッシュ戦略の最適化
- [ ] 並列実行の最適化
- [ ] メモリ使用量の削減

#### 5-3. ドキュメント整備（2-3日）
- [ ] API仕様書の作成
- [ ] チュートリアルの作成
- [ ] トラブルシューティングガイド

**フェーズ5完了予定**: 2025-12-05

---

## マイルストーン

| マイルストーン | 完了予定日 | 主要成果物 |
|--------------|-----------|-----------|
| **M1: 基本機能完成** | 2025-10-27 | 動作する2ステップ抽出、改善されたプロンプト |
| **M2: 実験評価完了** | 2025-11-05 | 全サブカテゴリ検証、精度レポート |
| **M3: プロンプト最適化完了** | 2025-11-15 | 50個のstep2プロンプト、アルゴリズム別実験 |
| **M4: 機能拡張完了** | 2025-11-25 | 外部LLM対応、カスタムルール、可視化 |
| **M5: 本番運用準備完了** | 2025-12-05 | エラーハンドリング、ドキュメント完備 |

---

## リスクと対策

### リスク1: Step 2でのフィールド抽出精度が低い

**影響度**: 高
**発生確率**: 中
**対策**:
- プロンプトの段階的改善
- マッピングルールの詳細検証
- サブカテゴリ構造体の定義見直し

### リスク2: AIが期待通りのJSON形式を返さない

**影響度**: 高
**発生確率**: 中
**対策**:
- プロンプトに厳格な出力形式を明示
- JSONサニタイズロジックの強化
- 外部LLMでの代替実装

### リスク3: 25個のサブカテゴリの管理が複雑化

**影響度**: 中
**発生確率**: 高
**対策**:
- 自動生成スクリプトの作成
- テンプレートの統一化
- コードレビューの徹底

### リスク4: 実験・評価に時間がかかる

**影響度**: 低
**発生確率**: 高
**対策**:
- 並列実験実行の活用
- 優先度の高いサブカテゴリから実施
- 自動化スクリプトの充実

---

## 関連ドキュメント

- [EXPERIMENT_PATTERNS.md](./EXPERIMENT_PATTERNS.md): 実験パターン仕様
- [LOG_SCHEMA.md](./LOG_SCHEMA.md): ログスキーマ定義
- [ARCHITECTURE.md](./ARCHITECTURE.md): アーキテクチャ設計
- [CLAUDE.md](../CLAUDE.md): プロジェクト概要

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 担当者 |
|------|----------|---------|--------|
| 2025-10-22 | 1.0 | 初版作成 | Claude Code |
| 2025-10-22 | 1.1 | ContentInfo構造体からhas*フィールドを削除（分割推定方式では不要） | Claude Code |
| 2025-10-22 | 1.2 | confidence削除、@Generableマクロ適用、プロンプト出力形式指定削除 | Claude Code |

---

**最終更新日**: 2025-10-22
**ドキュメント管理者**: プロジェクトチーム
