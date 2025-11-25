# 2ステップ抽出方式（分割推定方式）機能仕様書

## ドキュメント情報

- **作成日**: 2025-11-15
- **最終更新**: 2025-11-15 16:08
- **バージョン**: 1.0
- **対象リリース**: iOS 26+, macOS 26+
- **ドキュメント種別**: 機能仕様書

---

## 目次

1. [概要](#概要)
2. [機能要件](#機能要件)
3. [非機能要件](#非機能要件)
4. [ユースケース](#ユースケース)
5. [入力・出力仕様](#入力出力仕様)
6. [エラーハンドリング](#エラーハンドリング)
7. [制約事項](#制約事項)
8. [関連ドキュメント](#関連ドキュメント)

---

## 概要

### システムの目的

2ステップ抽出方式（分割推定方式）は、AIを活用してドキュメントからアカウント情報などの個人情報を高精度で抽出するシステムです。従来の単純推定方式の課題を解決し、カテゴリ判定と情報抽出を分離することで、より正確で柔軟な情報抽出を実現します。

### 背景と課題

従来の単純推定方式では、すべてのアカウント情報を一度のAI推論で抽出しようとするため、以下の課題がありました：

- **精度低下**: 複雑なドキュメントでは、一度にすべての情報を抽出することが困難で精度が低下する
- **プロンプト最適化の限界**: カテゴリごとに最適なプロンプトを適用できない
- **フィールド選択の不適切さ**: 抽出すべきフィールドの選択が不適切になる

### 解決アプローチ

2ステップ抽出方式は、以下の2段階の処理により課題を解決します：

1. **Step 1: カテゴリ判定** - ドキュメントの内容を分析し、適切なカテゴリを判定
2. **Step 2: 情報抽出** - 判定されたカテゴリに特化したプロンプトで情報を抽出

### 基本アーキテクチャ

```
入力: ドキュメント（テキスト）
  │
  ▼
Step 1: カテゴリ判定（2層構造）
  ├─ Step 1a: メインカテゴリ判定（5分類）
  │   └─ 出力: mainCategory (String)
  │
  └─ Step 1b: サブカテゴリ判定（25分類）
      └─ 出力: subCategory (String)
  │
  ▼
ContentInfo (mainCategory, subCategory)
  │
  ▼
Step 2: アカウント情報抽出
  ├─ サブカテゴリ定義ファイルから動的プロンプト生成
  ├─ AI推論による汎用JSON抽出
  └─ マッピングルール適用
  │
  ▼
出力: AccountInfo (統一フォーマット)
```

### 主要な特徴

1. **動的プロンプト生成**: カテゴリ定義ファイルから自動的にプロンプトを生成
2. **Single Source of Truth**: カテゴリ定義とマッピングルールを1つのJSONファイルで管理
3. **型定義不要**: JSON方式により、柔軟な拡張が可能
4. **カテゴリ階層**: 5つのメインカテゴリ × 5つのサブカテゴリ = 25分類

---

## 機能要件

### FR-1: カテゴリ判定機能

#### FR-1.1: メインカテゴリ判定（Step 1a）

**機能説明**: 入力ドキュメントを分析し、5つのメインカテゴリのうち最も適切なものを判定します。

**判定対象カテゴリ**:
- `personal`: 個人生活（自宅、教育、医療、連絡先など）
- `financial`: 金融・決済（銀行、カード、決済、保険、仮想通貨など）
- `digital`: デジタルサービス（サブスク、AI、SNS、EC、アプリなど）
- `work`: 仕事・ビジネス（サーバー、SaaS、開発ツールなど）
- `infrastructure`: インフラ・公的（通信、公共料金、行政、免許など）

**処理フロー**:
1. `CategoryDefinitionLoader`が`category_definitions.json`からカテゴリ定義を読み込み
2. メインカテゴリ判定用のプロンプトを動的生成
3. AIモデルに推論を依頼（JSON形式）
4. レスポンスから`mainCategory`フィールドを抽出（String型）

**出力**: `String`型のメインカテゴリID（例: `"work"`, `"financial"`）

#### FR-1.2: サブカテゴリ判定（Step 1b）

**機能説明**: Step 1aで判定されたメインカテゴリに基づき、25個のサブカテゴリのうち最も適切なものを判定します。

**サブカテゴリ構造**:
- 各メインカテゴリに5つのサブカテゴリを定義（計25分類）
- 例: `work` → `workServer`, `workSaaS`, `workDevelopment`, `workCommunication`, `workOther`

**処理フロー**:
1. Step 1aで判定された`mainCategory`を使用
2. `CategoryDefinitionLoader`が該当メインカテゴリのサブカテゴリ候補を取得
3. 各サブカテゴリの定義ファイル（`subcategories/{subCategoryId}.json`）から詳細情報を読み込み
4. サブカテゴリ判定用のプロンプトを動的生成
5. AIモデルに推論を依頼（JSON形式）
6. レスポンスから`subCategory`フィールドを抽出（String型）

**出力**: `String`型のサブカテゴリID（例: `"workServer"`, `"financialCreditCard"`）

#### FR-1.3: ContentInfo生成

**機能説明**: Step 1aとStep 1bの結果を統合し、`ContentInfo`構造体を生成します。

**データ構造**:
```swift
public struct ContentInfo {
    public var mainCategory: String  // 例: "work"
    public var subCategory: String    // 例: "workServer"
}
```

**用途**: Step 2の情報抽出で使用されるカテゴリ情報

### FR-2: アカウント情報抽出機能（Step 2）

#### FR-2.1: 動的プロンプト生成

**機能説明**: 判定されたサブカテゴリに基づき、最適化されたプロンプトを動的に生成します。

**プロンプト生成の流れ**:
1. `CategoryDefinitionLoader`がサブカテゴリ定義ファイル（`subcategories/{subCategoryId}.json`）を読み込み
2. 定義ファイル内の`mapping`構造からフィールド定義を取得
3. 各フィールドの名前、説明、必須/任意情報をプロンプトテンプレートに組み込み
4. テストデータと組み合わせてプロンプトを完成

**プロンプトの構成要素**:
- タスク説明（サブカテゴリに特化した情報抽出の依頼）
- サブカテゴリ情報（名前、説明）
- フィールド定義リスト（動的生成）
- 出力形式の指定（JSON形式）
- テストデータ

#### FR-2.2: 汎用JSON抽出

**機能説明**: AIモデルに推論を依頼し、サブカテゴリに特化したフィールドをJSON形式で抽出します。

**処理フロー**:
1. 動的生成されたプロンプトを使用してAI推論を実行
2. AIレスポンスからマークダウンコードブロック（```json ... ```）を抽出
3. JSON文字列をパースして汎用辞書（`[String: Any]`）に変換

**出力形式**: 汎用JSON辞書
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

#### FR-2.3: マッピングルール適用

**機能説明**: サブカテゴリごとに定義されたマッピングルールに従い、汎用JSON辞書を統一フォーマット`AccountInfo`に変換します。

**マッピングルールの種類**:

1. **直接マッピング**: `mappingKey`が指定されている場合
   - JSONフィールド → AccountInfoフィールドに直接マッピング
   - 例: `JSON["serviceName"]` → `AccountInfo.title`
   - 例: `JSON["loginID"]` → `AccountInfo.userID`

2. **noteフィールドへの追加**: `mappingKey`が`null`または未指定の場合
   - JSONフィールドの値を`AccountInfo.note`に追加
   - 例: `JSON["sshAuthKey"]` → `AccountInfo.note`に "SSH鍵情報: <値>" を追加

**マッピングルールの定義場所**: サブカテゴリ定義ファイル内の`mapping`構造

**処理フロー**:
1. `SubCategoryConverter`がサブカテゴリ定義ファイルを読み込み
2. `mapping`構造からマッピングルールを取得
3. 汎用JSON辞書の各フィールドに対してマッピングルールを適用
4. 統一フォーマット`AccountInfo`を生成

**出力**: `AccountInfo`構造体（統一フォーマット）

### FR-3: カテゴリ定義管理機能

#### FR-3.1: カテゴリ定義ファイルの読み込み

**機能説明**: `category_definitions.json`からメインカテゴリとサブカテゴリの定義を読み込みます。

**定義ファイルの構造**:
- メインカテゴリ定義（5個）
  - id, name (ja/en), description (ja/en), examples (ja/en), subcategories
- プロンプトテンプレート
  - mainCategoryJudgment (ja/en)
  - subCategoryJudgment (ja/en)

**キャッシュ機能**: 初回読み込み後はメモリキャッシュを使用

#### FR-3.2: サブカテゴリ定義ファイルの読み込み

**機能説明**: `subcategories/{subCategoryId}.json`からサブカテゴリの詳細定義を読み込みます。

**定義ファイルの構造**:
- id: サブカテゴリID
- name: 日本語・英語の表示名
- description: カテゴリの説明
- examples: 具体例
- **mapping**: フィールド定義とマッピングルールを統合
  - 各フィールドの定義（name, description, required, mappingKey, format, type）

**キャッシュ機能**: サブカテゴリごとにメモリキャッシュを使用

### FR-4: ログ・メトリクス機能

#### FR-4.1: 構造化ログ出力

**機能説明**: 2ステップ抽出の実行結果を構造化ログとして出力します。

**ログに含まれる情報**:
- パターン、レベル、イテレーション
- 抽出方法（method）
- 言語（language）
- カテゴリ判定結果（`two_steps_category`）
  - `main_category`: メインカテゴリID
  - `main_category_display`: メインカテゴリ表示名（日本語）
  - `sub_category`: サブカテゴリID
  - `sub_category_display`: サブカテゴリ表示名（日本語）
- 抽出結果（expected_fields, unexpected_fields）

#### FR-4.2: メトリクス生成

**機能説明**: 2ステップ抽出の処理時間と効果性を測定します。

**メトリクス項目**:
- `step1Time`: Step 1（カテゴリ判定）の処理時間（秒）
- `step2Time`: Step 2（情報抽出）の処理時間（秒）
- `totalTime`: 総処理時間（秒）
- `detectedCategory`: 判定されたカテゴリ（`"mainCategory/subCategory"`形式）
- `extractedInfoTypes`: 抽出された情報タイプ数
- `strategyEffectiveness`: 抽出戦略の効果性（0.0-1.0）
- `baseMetrics`: 基本メトリクス（抽出時間、メモリ使用量など）

---

## 非機能要件

### NFR-1: 性能要件

#### NFR-1.1: 処理時間

- **Step 1（カテゴリ判定）**: 平均2-3秒以内
- **Step 2（情報抽出）**: 平均1-2秒以内
- **総処理時間**: 平均4-5秒以内

#### NFR-1.2: メモリ使用量

- カテゴリ定義ファイルのキャッシュ: 10MB以下
- サブカテゴリ定義ファイルのキャッシュ: 各ファイル1MB以下（25ファイルで25MB以下）

### NFR-2: 信頼性要件

#### NFR-2.1: エラーハンドリング

- 必須リソース（カテゴリ定義ファイル）が見つからない場合は`fatalError`で即座に検出
- JSON解析エラー時は詳細なエラーメッセージとAIレスポンスをログに記録
- サブカテゴリ定義ファイルが見つからない場合は`fatalError`で即座に検出

#### NFR-2.2: データ整合性

- カテゴリ定義ファイルの形式が不正な場合は起動時に検出
- マッピングルールの適用時に型チェックを実施

### NFR-3: 保守性要件

#### NFR-3.1: 拡張性

- 新しいサブカテゴリを追加する際は、定義ファイル（JSON）を1つ追加するだけで対応可能
- 新しいフィールドを追加する際は、定義ファイル内の`mapping`構造を編集するだけで対応可能

#### NFR-3.2: Single Source of Truth

- カテゴリ定義: `category_definitions.json`
- サブカテゴリ定義: `subcategories/*.json`（25ファイル）
- プロンプト: 定義ファイルから動的生成
- マッピングルール: サブカテゴリ定義ファイル内に統合

### NFR-4: 互換性要件

#### NFR-4.1: プラットフォーム

- iOS 26.0以上
- macOS 26.0以上

#### NFR-4.2: 抽出方式

- **TwoSteps抽出はJSON方式のみサポート**
- `@Generable`マクロを使用した方式はサポートしない
- 理由: 動的プロンプト生成により型定義が不要になったため

---

## ユースケース

### UC-1: サーバー情報の抽出

**前提条件**: ユーザーがサーバーのログイン情報を含むドキュメントを提供

**シナリオ**:
1. システムがドキュメントを受け取る
2. **Step 1a**: メインカテゴリを判定 → `"work"`を判定
3. **Step 1b**: サブカテゴリを判定 → `"workServer"`を判定
4. **Step 2**: `workServer`用のプロンプトで情報抽出
   - サービス名、ログインID、パスワード、ホスト、ポート、SSH鍵などを抽出
5. マッピングルールを適用して`AccountInfo`に変換
6. 結果を返す

**期待結果**: 
- `AccountInfo.title`: サービス名
- `AccountInfo.userID`: ログインID
- `AccountInfo.password`: パスワード
- `AccountInfo.host`: ホスト名/IPアドレス
- `AccountInfo.port`: ポート番号
- `AccountInfo.authKey`: SSH鍵（存在する場合）

### UC-2: クレジットカード情報の抽出

**前提条件**: ユーザーがクレジットカード情報を含むドキュメントを提供

**シナリオ**:
1. システムがドキュメントを受け取る
2. **Step 1a**: メインカテゴリを判定 → `"financial"`を判定
3. **Step 1b**: サブカテゴリを判定 → `"financialCreditCard"`を判定
4. **Step 2**: `financialCreditCard`用のプロンプトで情報抽出
   - カード名、カード番号、有効期限、セキュリティコードなどを抽出
5. マッピングルールを適用して`AccountInfo`に変換
6. 結果を返す

**期待結果**:
- `AccountInfo.title`: カード名
- `AccountInfo.number`: カード番号
- `AccountInfo.note`: 有効期限、セキュリティコードなどの追加情報

### UC-3: サブスクリプション情報の抽出

**前提条件**: ユーザーがNetflixなどのサブスクリプション情報を含むドキュメントを提供

**シナリオ**:
1. システムがドキュメントを受け取る
2. **Step 1a**: メインカテゴリを判定 → `"digital"`を判定
3. **Step 1b**: サブカテゴリを判定 → `"digitalSubscription"`を判定
4. **Step 2**: `digitalSubscription`用のプロンプトで情報抽出
   - サービス名、ログインID、パスワード、URLなどを抽出
5. マッピングルールを適用して`AccountInfo`に変換
6. 結果を返す

**期待結果**:
- `AccountInfo.title`: サービス名（例: "Netflix"）
- `AccountInfo.userID`: ログインID/メールアドレス
- `AccountInfo.password`: パスワード
- `AccountInfo.url`: ログインURL

---

## 入力・出力仕様

### 入力仕様

#### 入力データ

**型**: `String`

**内容**: ドキュメントのテキスト（メッセージ、会話ログ、設定ファイルなど）

**例**:
```
AWS EC2サーバー情報
ホスト: 22.22.22.22
ポート: 22010
ユーザー名: admin
パスワード: SecurePass18329
SSH鍵: -----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

#### 入力パラメータ

- `testcase`: テストケース名（例: `"Chat"`, `"Contract"`）
- `level`: レベル（1, 2, 3）
- `method`: 抽出方式（`ExtractionMethod.json`のみサポート）
- `algo`: アルゴリズム（例: `"abs"`, `"strict"`）
- `language`: 言語（`PromptLanguage.japanese` または `PromptLanguage.english`）
- `useTwoSteps`: 2ステップ抽出を使用するか（`true`）

### 出力仕様

#### 主要出力

**型**: `(AccountInfo, ExtractionMetrics, String, String?, ContentInfo?)`

**構成要素**:

1. **AccountInfo**: 抽出されたアカウント情報（統一フォーマット）
   ```swift
   public struct AccountInfo {
       public var title: String?      // サービス名
       public var userID: String?    // ログインID
       public var password: String?   // パスワード
       public var url: String?        // ログインURL
       public var number: String?     // 識別番号
       public var note: String?       // 備考・メモ
       public var host: String?       // ホスト名/IPアドレス
       public var port: Int?          // ポート番号
       public var authKey: String?    // 認証キー
   }
   ```

2. **ExtractionMetrics**: 抽出メトリクス
   - `extractionTime`: AI抽出処理時間（秒）
   - `totalTime`: 総処理時間（秒）
   - `memoryUsed`: メモリ使用量（MB）
   - `textLength`: 入力テキスト長（文字数）
   - `extractedFieldsCount`: 抽出されたフィールド数
   - `confidence`: 信頼度スコア
   - `isValid`: 抽出結果が有効かどうか
   - `validationResult`: バリデーション結果

3. **String**: AI生レスポンス（デバッグ用）

4. **String?**: リクエストコンテンツ（オプション）

5. **ContentInfo?**: カテゴリ判定結果（2ステップ抽出時のみ）
   ```swift
   public struct ContentInfo {
       public var mainCategory: String  // 例: "work"
       public var subCategory: String    // 例: "workServer"
   }
   ```

#### ログ出力

**形式**: JSON形式の構造化ログ

**主要フィールド**:
- `pattern`: パターン名
- `level`: レベル
- `iteration`: イテレーション番号
- `method`: 抽出方式
- `language`: 言語
- `two_steps_category`: カテゴリ判定結果
  - `main_category`: メインカテゴリID
  - `main_category_display`: メインカテゴリ表示名
  - `sub_category`: サブカテゴリID
  - `sub_category_display`: サブカテゴリ表示名
- `expected_fields`: 期待されるフィールド
- `unexpected_fields`: 予期しないフィールド

---

## エラーハンドリング

### エラー種別

#### E-1: リソースエラー

**E-1.1: カテゴリ定義ファイルが見つからない**

- **エラー**: `fatalError`
- **原因**: `category_definitions.json`が存在しない、またはパスが間違っている
- **対処**: プロジェクトのビルド設定とリソース配置を確認

**E-1.2: サブカテゴリ定義ファイルが見つからない**

- **エラー**: `fatalError`
- **原因**: `subcategories/{subCategoryId}.json`が存在しない
- **対処**: 該当するサブカテゴリ定義ファイルを作成

#### E-2: データ形式エラー

**E-2.1: JSON解析エラー**

- **エラー**: `ExtractionError.invalidJSONFormat(aiResponse: String?)`
- **原因**: AIレスポンスが有効なJSON形式ではない
- **対処**: 
  - AIレスポンスをログに記録
  - マークダウンコードブロックからJSONを抽出する処理を強化
  - プロンプトを改善してJSON形式を明確に指示

**E-2.2: カテゴリ定義ファイルのデコードエラー**

- **エラー**: `fatalError`
- **原因**: JSONファイルの形式が不正
- **対処**: JSONファイルの内容とフォーマットを確認

#### E-3: メソッドエラー

**E-3.1: Generable方式が指定された**

- **エラー**: `ExtractionError.methodNotSupported("Two-steps extraction only supports JSON method")`
- **原因**: TwoSteps抽出で`ExtractionMethod.generable`が指定された
- **対処**: `ExtractionMethod.json`を使用

#### E-4: 入力エラー

**E-4.1: 無効な入力データ**

- **エラー**: `ExtractionError.invalidInput`
- **原因**: 入力データが空、または形式が不正
- **対処**: 入力データの妥当性を確認

### エラーログ

すべてのエラーは以下の情報を含むログに記録されます：

- エラーの種類
- エラーが発生したステップ（Step 1a, Step 1b, Step 2）
- AIレスポンス（該当する場合）
- スタックトレース（デバッグモード）

---

## 制約事項

### C-1: プラットフォーム制約

- iOS 26.0以上、macOS 26.0以上でのみ動作
- Apple Intelligence（FoundationModels）が利用可能なデバイスのみ

### C-2: 抽出方式制約

- **TwoSteps抽出はJSON方式のみサポート**
- `@Generable`マクロを使用した方式は使用不可
- 理由: 動的プロンプト生成により型定義が不要になったため

### C-3: カテゴリ制約

- メインカテゴリは5分類に固定（personal, financial, digital, work, infrastructure）
- サブカテゴリは各メインカテゴリに5つずつ、計25分類に固定
- 新しいカテゴリを追加する場合は、定義ファイルを編集する必要がある

### C-4: プロンプト制約

- プロンプトは定義ファイルから動的生成されるため、静的なプロンプトファイルは使用しない
- プロンプトのカスタマイズは定義ファイルの編集により行う

### C-5: マッピングルール制約

- マッピングルールはサブカテゴリ定義ファイル内に統合されている
- 独立したマッピングルールファイルは使用しない
- 新しいマッピングルールを追加する場合は、定義ファイルを編集する必要がある

---

## 関連ドキュメント

- [TWO_STEPS_EXTRACTION_SPEC.md](./TWO_STEPS_EXTRACTION_SPEC.md): 実装仕様書（詳細な実装内容）
- [EXPERIMENT_PATTERNS.md](./EXPERIMENT_PATTERNS.md): 実験パターン仕様
- [LOG_SCHEMA.md](./LOG_SCHEMA.md): ログスキーマ定義
- [ARCHITECTURE.md](./ARCHITECTURE.md): アーキテクチャ設計
- [CLAUDE.md](../CLAUDE.md): プロジェクト概要

---

**最終更新日**: 2025-11-15 16:08
**ドキュメント管理者**: プロジェクトチーム

