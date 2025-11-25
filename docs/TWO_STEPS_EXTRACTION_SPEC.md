# 2ステップ抽出方式（分割推定方式）実装仕様書

## ドキュメント情報

- **作成日**: 2025-10-22
- **最終更新**: 2025-11-06
- **バージョン**: 2.0
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
Step 1: カテゴリ判定（2層構造）- JSON方式
  ├─ Step 1a: メインカテゴリ判定（5分類）
  └─ Step 1b: サブカテゴリ判定（各5分類、計25分類）

Step 2: アカウント情報抽出 - JSON方式 + 動的プロンプト生成
  ├─ CategoryDefinitionLoaderによる動的プロンプト生成
  ├─ FoundationModelsExtractor.extractGenericJSON()による汎用JSON抽出
  └─ SubCategoryConverterによるマッピングルール適用
```

### 重要な設計変更（v2.0）

**@Generableマクロの廃止**:
- TwoSteps抽出は**JSON方式のみ**サポート
- @Generable専用構造体（25個）はすべて削除
- MainCategoryInfo/SubCategoryInfo構造体も削除
- 直接JSON解析により、型定義なしで動的に抽出

**Single Source of Truth**:
- カテゴリ定義: `category_definitions.json`
- サブカテゴリ定義: `subcategories/*.json`（25ファイル）
- プロンプト: 定義ファイルから動的生成
- マッピングルール: サブカテゴリ定義ファイル内に統合

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
│             (2ステップ抽出のコア処理 - JSON方式のみ)      │
└─────┬────────────────────────────────────────┬──────────┘
      │                                        │
      │ Step 1: カテゴリ判定                    │ Step 2: 情報抽出
      ▼                                        ▼
┌──────────────────┐              ┌────────────────────────┐
│ analyzeDocument  │              │ extractAccountInfo     │
│   TypeJSON()     │              │     BySteps()          │
└────┬─────────────┘              └────────┬───────────────┘
     │                                     │
     ├─ Step 1a: 直接JSON解析 ─────┐       │
     │  メインカテゴリ判定           │       │
     │  → String                   │       │
     │                             │       │
     └─ Step 1b: 直接JSON解析 ─────┤       │
        サブカテゴリ判定             │       │
        → String                   │       │
                                   │       │
                                   ▼       │
                            ┌──────────────┴───────────────┐
                            │     ContentInfo               │
                            │  - mainCategory: String       │
                            │  - subCategory: String        │
                            └────────┬──────────────────────┘
                                     │
                  ┌──────────────────┼──────────────────┐
                  │                  │                  │
                  ▼                  ▼                  ▼
      ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐
      │ CategoryDef     │  │ FoundationModels│  │ SubCategory    │
      │   Loader        │  │   Extractor     │  │  Converter     │
      │ (動的プロンプト) │  │ extractGeneric  │  │ (マッピング    │
      │                 │  │   JSON()        │  │  ルール適用)    │
      └────────┬────────┘  └────────┬────────┘  └────────┬───────┘
               │                    │                    │
               └────────────────────┴────────────────────┘
                                    │
                                    ▼
                           ┌──────────────────┐
                           │   [String: Any]  │
                           │  (汎用JSON辞書)   │
                           └────────┬─────────┘
                                    │
                                    ▼
                           ┌──────────────────┐
                           │   AccountInfo    │
                           │ (統一フォーマット) │
                           └──────────────────┘
```

### クラス関連図

```
┌─────────────────────┐
│  UnifiedExtractor   │
│  - extract()        │
└──────┬──────────────┘
       │ 使用
       ▼
┌──────────────────────────┐
│ TwoStepsProcessor        │
│ - analyzeDocumentType    │
│   JSON()                 │
│ - extractAccountInfo     │
│   BySteps()              │
└──────┬───────────────────┘
       │ 使用
       ├──────────────────┐
       ▼                  ▼
┌────────────────┐  ┌────────────────────┐
│ CategoryDef    │  │ FoundationModels   │
│   Loader       │  │   Extractor        │
│ - generate     │  │ - extract()        │
│   MainCategory │  │ - extractGeneric   │
│   Judgment     │  │   JSON()           │
│   Prompt()     │  └─────────┬──────────┘
│ - generate     │            │
│   SubCategory  │            │ 使用
│   Judgment     │            ▼
│   Prompt()     │   ┌────────────────────┐
│ - generate     │   │   JSONExtractor    │
│   Extraction   │   │ - extractJSON      │
│   Prompt()     │   │   String()         │
└────────┬───────┘   └────────────────────┘
         │
         │ 参照
         ▼
┌─────────────────────────┐
│ カテゴリ定義ファイル     │
│ - category_definitions  │
│   .json                 │
│ - subcategories/*.json  │
│   (25ファイル)           │
│   └─ mapping構造        │
└─────────────────────────┘
         │
         │ 使用
         ▼
┌──────────────────────┐
│ SubCategoryConverter │
│ - convert()          │
│   (定義ファイル内の   │
│    mappingを適用)     │
└──────────────────────┘
```

---

## 実装仕様

### Step 1a: メインカテゴリ判定（JSON方式）

#### 処理フロー

1. `CategoryDefinitionLoader.generateMainCategoryJudgmentPrompt()`でプロンプトを動的生成
   - `category_definitions.json`からカテゴリ情報を読み込み
   - テストデータと組み合わせてプロンプトを構築
2. `ModelExtractor.extract()`で推論実行（JSON形式）
3. レスポンスからマークダウンコードブロックを抽出
4. JSON解析して`mainCategory`フィールドを取得（String型）
5. `ContentInfo`の構築に使用

#### カテゴリ定義（5分類）

| カテゴリ | rawValue | 説明 | 例 |
|---------|----------|------|-----|
| 個人生活 | personal | 自宅、教育、医療、連絡先 | 自宅住所、習い事、病院 |
| 金融・決済 | financial | 銀行、カード、決済、保険、仮想通貨 | 銀行口座、クレカ |
| デジタルサービス | digital | サブスク、AI、SNS、EC、アプリ | Netflix、ChatGPT |
| 仕事・ビジネス | work | サーバー、SaaS、開発ツール | AWS EC2、Slack |
| インフラ・公的 | infrastructure | 通信、公共料金、行政、免許 | docomo、マイナポータル |

#### 出力形式

**JSON形式** (AIが返す):
```json
{
  "mainCategory": "work"
}
```

**処理結果**: `String` 型（例: `"work"`, `"financial"`, `"personal"`）

#### 実装クラス

- **ファイル**: `TwoStepsProcessor.swift`
- **メソッド**: `judgeMainCategoryJSON()`
- **補助クラス**:
  - `CategoryDefinitionLoader`: プロンプト動的生成
  - `JSONExtractor`: JSON文字列解析（使用していない - 直接`JSONSerialization`を使用）

---

### Step 1b: サブカテゴリ判定（JSON方式）

#### 処理フロー

1. `CategoryDefinitionLoader.generateSubCategoryJudgmentPrompt()`でプロンプトを動的生成
   - Step 1aで判定された`mainCategoryId`を使用
   - `category_definitions.json`から該当するサブカテゴリ候補を取得
   - 各サブカテゴリの定義ファイル（`subcategories/{subCategoryId}.json`）から詳細情報を読み込み
2. `ModelExtractor.extract()`で推論実行（JSON形式）
3. レスポンスからマークダウンコードブロックを抽出
4. JSON解析して`subCategory`フィールドを取得（String型）
5. `ContentInfo`の構築に使用

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

#### 出力形式

**JSON形式** (AIが返す):
```json
{
  "subCategory": "workServer"
}
```

**処理結果**: `String` 型（例: `"workServer"`, `"financialCreditCard"`, `"personalHome"`）

#### ContentInfo構造体（カテゴリ判定結果の集約）

```swift
@available(iOS 26.0, macOS 26.0, *)
public struct ContentInfo: Codable, Equatable, Sendable {
    public var mainCategory: String  // 例: "work"
    public var subCategory: String   // 例: "workServer"
}
```

**設計原則**:
- **JSON方式のみ**: TwoSteps抽出では@Generableマクロを使用しない
- **型定義不要**: String型で柔軟にカテゴリを管理
- **動的プロンプト**: カテゴリ定義ファイルから動的生成
- **Single Source of Truth**: category_definitions.jsonとsubcategories/*.jsonが唯一の情報源

#### 実装クラス

- **ファイル**: `TwoStepsProcessor.swift`
- **メソッド**: `judgeSubCategoryJSON()`
- **補助クラス**:
  - `CategoryDefinitionLoader`: プロンプト動的生成、サブカテゴリ候補取得

---

### Step 2: アカウント情報抽出（JSON方式 + 動的プロンプト生成）

#### 処理フロー

1. `CategoryDefinitionLoader.generateExtractionPrompt()`で動的プロンプト生成
   - Step 1で判定された`subCategoryId`を使用
   - サブカテゴリ定義ファイル（`subcategories/{subCategoryId}.json`）から：
     - フィールド定義（`schema.fields`）
     - 説明文（`description`）
     - 例（`examples`）
   - これらをテンプレートに組み込んでプロンプトを構築
2. `ModelExtractor.extract()`で推論実行（JSON形式）
3. AIレスポンスから汎用JSON辞書（`[String: Any]`）を抽出
4. `SubCategoryConverter.convert()`でマッピングルールを適用
   - サブカテゴリ定義ファイル内の`mapping`構造を使用
   - `directMapping`: 直接フィールドにマッピング
   - `noteAppendMapping`: note フィールドに追加
5. 統一フォーマット `AccountInfo` に変換

#### 動的プロンプト生成のメリット

**v1.x（削除された方式）**:
- 25個の@Generable構造体を手動定義
- 25個のマッピングルールJSONファイルを手動管理
- 構造体とマッピングルールの二重管理

**v2.0（現在の方式）**:
- サブカテゴリ定義ファイル（25個）のみを管理
- フィールド定義とマッピングルールを統合
- 型定義不要で柔軟な拡張が可能
- Single Source of Truthの実現

#### サブカテゴリ定義ファイルの構造

**配置**: `Sources/AITest/CategoryDefinitions/subcategories/{subCategoryId}.json`

**例: workServer.json**
```json
{
  "id": "workServer",
  "name": {
    "ja": "サーバー・VPS",
    "en": "Server・VPS"
  },
  "description": {
    "ja": "サーバー・VPS・クラウドサービスに関する情報",
    "en": "Information related to servers, VPS, and cloud services"
  },
  "examples": {
    "ja": [],
    "en": []
  },
  "mapping": {
    "ja": [
      {
        "name": "serviceName",
        "mappingKey": "title",
        "required": true,
        "description": "サービス名"
      },
      {
        "name": "loginID",
        "mappingKey": "userID",
        "description": "ログイン用のID・ユーザー名"
      },
      {
        "name": "loginPassword",
        "mappingKey": "password",
        "description": "ログインパスワード"
      },
      {
        "name": "loginURL",
        "mappingKey": "url",
        "description": "ログインURL"
      },
      {
        "name": "hostOrIPAddress",
        "mappingKey": "host",
        "description": "ホスト名・IPアドレス"
      },
      {
        "name": "portNumber",
        "mappingKey": "port",
        "description": "ポート番号"
      },
      {
        "name": "sshAuthKey",
        "mappingKey": "authKey",
        "description": "SSH鍵情報"
      },
      {
        "name": "note",
        "required": true,
        "description": "備考・メモ・追加情報"
      }
    ]
  }
}
```

**フィールド説明**:
- `name`: AIに抽出を依頼するフィールド名（プロンプトに使用）
- `mappingKey`: AccountInfoのどのフィールドにマッピングするか
- `required`: 必須フィールドかどうか
- `description`: フィールドの説明（プロンプトに使用）

**マッピングの仕組み**:
- `mappingKey`が指定されている → 直接マッピング
- `mappingKey`が`null`または未指定 → noteフィールドに追加

#### 実装クラス

- **ファイル**: `TwoStepsProcessor.swift`
- **メソッド**: `extractAccountInfoBySteps()` → `extractAndConvertBySubCategoryJSON()`
- **内部呼び出し**:
  - `CategoryDefinitionLoader.generateExtractionPrompt()`: 動的プロンプト生成
  - `ModelExtractor.extract()`: AI推論実行
  - `JSONExtractor.extractJSONString()`: JSON文字列解析（使用していない）
  - `SubCategoryConverter.convert()`: マッピングルール適用

---

## データ構造

### ContentInfo（カテゴリ判定結果）

```swift
@available(iOS 26.0, macOS 26.0, *)
public struct ContentInfo: Codable, Equatable, Sendable {
    public var mainCategory: String  // 例: "work"
    public var subCategory: String   // 例: "workServer"
}
```

**設計原則**:
- String型で柔軟にカテゴリを管理
- enum不要（動的にカテゴリを追加・変更可能）
- confidenceフィールド削除（AI自己評価は信頼性が低い）
- has*フラグ削除（サブカテゴリ判定により抽出内容が決まる）

### サブカテゴリ定義ファイル（25ファイル）

**v2.0の重要な変更**: @Generable専用構造体（25個）を削除し、サブカテゴリ定義ファイルに統合

**配置**: `Sources/AITest/CategoryDefinitions/subcategories/*.json`

**管理対象**:
- id: サブカテゴリID
- name: 日本語・英語の表示名
- description: カテゴリの説明
- examples: 具体例
- **mapping**: フィールド定義とマッピングルールを統合

**利点**:
- **型定義不要**: Swift構造体を定義せずに動的にフィールドを管理
- **Single Source of Truth**: 1つのJSONファイルですべてを管理
- **柔軟な拡張**: 新しいフィールドを追加する際、定義ファイルのみを編集
- **保守性向上**: 二重管理（構造体+マッピングルール）を排除

### 汎用JSON辞書（`[String: Any]`）

Step 2の抽出結果は型付けされた構造体ではなく、汎用JSON辞書として返されます：

```swift
let jsonResult: [String: Any] = [
    "serviceName": "AWS EC2",
    "loginID": "admin",
    "loginPassword": "SecurePass18329",
    "loginURL": nil,
    "hostOrIPAddress": nil,
    "portNumber": nil,
    "sshAuthKey": nil,
    "note": "AWS EC2サーバーのログイン情報"
]
```

この汎用辞書を`SubCategoryConverter`がマッピングルールに従って`AccountInfo`に変換します。

---

## プロンプト生成（動的）

### v2.0の重要な変更

**プロンプトテンプレートファイルの廃止**: 静的なテンプレートファイルから動的プロンプト生成に変更

### 動的プロンプト生成の仕組み

#### Step 1a: メインカテゴリ判定プロンプト

**生成メソッド**: `CategoryDefinitionLoader.generateMainCategoryJudgmentPrompt()`

**情報源**: `category_definitions.json`

**プロンプト構成**:
1. タスク説明（カテゴリ判定の依頼）
2. カテゴリ一覧（id、name、description、examples）
3. 出力形式の指定（JSON形式）
4. テストデータ

#### Step 1b: サブカテゴリ判定プロンプト

**生成メソッド**: `CategoryDefinitionLoader.generateSubCategoryJudgmentPrompt()`

**情報源**:
- `category_definitions.json`: サブカテゴリ候補リスト
- `subcategories/{subCategoryId}.json`: 各サブカテゴリの詳細情報

**プロンプト構成**:
1. タスク説明（サブカテゴリ判定の依頼）
2. メインカテゴリ情報（Step 1aの結果）
3. サブカテゴリ候補一覧（id、name、description、examples）
4. 出力形式の指定（JSON形式）
5. テストデータ

#### Step 2: アカウント情報抽出プロンプト

**生成メソッド**: `CategoryDefinitionLoader.generateExtractionPrompt()`

**情報源**: `subcategories/{subCategoryId}.json`

**プロンプト構成**:
1. タスク説明（情報抽出の依頼）
2. サブカテゴリ情報（name、description）
3. **フィールド定義リスト**（mapping.jaから動的生成）:
   - 各フィールドの名前
   - 各フィールドの説明
   - 必須/任意の指定
4. 出力形式の指定（JSON形式）
5. テストデータ

### 動的プロンプト生成のメリット

1. **メンテナンス性**: プロンプトを定義ファイルから自動生成するため、フィールド追加時にプロンプトファイルを手動編集する必要がない
2. **一貫性**: 定義ファイルとプロンプトの内容が自動的に同期
3. **拡張性**: 新しいサブカテゴリを追加する際、定義ファイルを1つ追加するだけで対応可能
4. **言語切り替え**: 日本語・英語を定義ファイル内で管理し、動的に切り替え

### プロンプト設計原則

1. **JSON形式の明示的な指示**: AIに対してJSON形式での出力を明確に指示
2. **単一の値を選択**: 複数の値を「|」で区切らない
3. **confidenceは不要**: AI自己評価の信頼性が低いため使用しない
4. **例示の明確化**: 各カテゴリの具体例を豊富に提示

---

## マッピングルール

### v2.0の重要な変更

**独立したマッピングルールファイルの廃止**: サブカテゴリ定義ファイル内に統合

### 統合されたマッピングルール

**配置**: `Sources/AITest/CategoryDefinitions/subcategories/*.json` 内の `mapping` フィールド

**v1.x（廃止）**:
- 25個のサブカテゴリ定義構造体（Swift）
- 25個のマッピングルールファイル（JSON）
- 2つのシステムを別々に管理

**v2.0（現在）**:
- 25個のサブカテゴリ定義ファイル（JSON）
- フィールド定義とマッピングルールを1つのファイルで管理
- Single Source of Truth

### マッピングルールの構造

サブカテゴリ定義ファイル内の `mapping` フィールド：

```json
{
  "mapping": {
    "ja": [
      {
        "name": "serviceName",
        "mappingKey": "title",
        "required": true,
        "description": "サービス名"
      },
      {
        "name": "sshAuthKey",
        "mappingKey": "authKey",
        "description": "SSH鍵情報"
      },
      {
        "name": "note",
        "description": "備考・メモ"
      }
    ]
  }
}
```

### マッピングの動作

**SubCategoryConverter.convert()**がマッピングを実行：

1. **直接マッピング**: `mappingKey`が指定されている場合
   ```
   JSON["serviceName"] → AccountInfo.title
   JSON["loginID"] → AccountInfo.userID
   ```

2. **noteフィールドへの追加**: `mappingKey`が`null`または未指定の場合
   ```
   JSON["sshAuthKey"] → AccountInfo.note に "SSH鍵情報: <値>" を追加
   ```

### マッピングルールの読み込み

- **クラス**: `CategoryDefinitionLoader`
- **メソッド**: `loadSubCategoryDefinition(subCategoryId:)`
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
| 2025-11-06 | 2.0 | **大規模アーキテクチャ変更**: @Generable構造体廃止、動的プロンプト生成、Single Source of Truth実現 | Claude Code |

### v2.0 主要変更点

**削除されたコンポーネント（約515行）**:
- 7個の@Generable抽出構造体（ExtractionStructs.swift全体）
- MainCategoryInfo/SubCategoryInfo構造体
- 25個のサブカテゴリ専用構造体
- 9個のJSON抽出メソッド
- 独立したマッピングルールファイル（25個）
- 静的プロンプトテンプレートファイル

**追加されたコンポーネント**:
- CategoryDefinitionLoader: 動的プロンプト生成
- 統合されたサブカテゴリ定義ファイル（mapping含む）
- extractGenericJSON(): 汎用JSON抽出
- 動的カテゴリ管理システム

**設計原則の変更**:
- TwoSteps抽出はJSON方式のみサポート
- 型定義不要（動的JSON抽出）
- Single Source of Truth（category_definitions.json + subcategories/*.json）
- プロンプトの動的生成

---

**最終更新日**: 2025-11-06
**ドキュメント管理者**: プロジェクトチーム
