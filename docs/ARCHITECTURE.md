# AITest アーキテクチャ設計書

## 概要

AITestは、iOS/macOS（iOS 26+/macOS 26+）でFoundationModels APIを利用したアカウント情報抽出の実験・評価を行うプロジェクトです。主な目的は以下の通りです：

- **@Generable/@Guideマクロのチューニング**: FoundationModels特有のマクロの最適な使用方法を実験的に検証
- **プロンプトのチューニング**: 抽象指示、厳格指示、人格指示などの指示スタイルと例示の有無による性能比較
- **抽出方法の提案**: @Generable（型安全）、JSONフォーマットでの抽出精度と性能の比較
- **FoundationModels vs 外部LLM**: AI部分のみを置き換えて性能を客観的に比較
- **2ステップ抽出**: ドキュメントタイプ判定と段階的抽出による精度向上

## システム構成

```
AITest/
├── Sources/
│   ├── AITest/              # メインライブラリ
│   │   ├── AccountInfo.swift           # アカウント情報モデル定義
│   │   ├── UnifiedExtractor.swift      # 統一抽出フロー
│   │   ├── ModelExtractor.swift        # モデル抽象化プロトコル
│   │   ├── FoundationModelsExtractor.swift  # FoundationModels実装
│   │   ├── ExternalLLMExtractor.swift  # 外部LLM実装
│   │   ├── TwoStepsProcessor.swift     # 2ステップ抽出処理
│   │   ├── CommonExtractionProcessor.swift  # 共通処理
│   │   ├── JSONExtractor.swift         # JSON解析・サニタイズ
│   │   ├── CategoryDefinitionLoader.swift   # カテゴリ定義読み込み
│   │   ├── SubCategoryConverter.swift  # サブカテゴリ変換
│   │   ├── PatternDefinitions.swift    # 実験パターン定義
│   │   ├── TestDataLoader.swift        # テストデータ読み込み
│   │   ├── AccountAnalysis.swift       # アカウント情報分析
│   │   ├── LogWrapper.swift           # ログラッパー
│   │   ├── ReportGenerator.swift       # レポート生成
│   │   ├── ContentView.swift          # SwiftUIメインUI
│   │   └── Prompts/                    # プロンプトテンプレート
│   │       ├── abstract_generable_ja.txt
│   │       ├── abstract_json_ja.txt
│   │       └── ...
│   └── AITestApp/           # コマンドラインアプリ
│       ├── main.swift                  # エントリーポイント
│       └── TestData/                   # テストデータ
├── Tests/
│   └── AITestTests/         # テストスイート
├── scripts/                 # 実験実行・レポート生成スクリプト
│   ├── run_experiments.py              # 逐次実験実行
│   ├── generate_combined_report.py     # 統合レポート生成
│   └── ...
├── commands/                # AI実行用コマンドファイル
├── test_logs/              # 実験ログ出力ディレクトリ
├── reports/                # 最終レポート格納ディレクトリ
└── docs/                   # プロジェクトドキュメント
```

## アーキテクチャパターン

### レイヤードアーキテクチャ

- **Presentation Layer**: SwiftUIベースのUIコンポーネント（ContentView, ResultsViews）
- **Application Layer**: 統一抽出フロー（UnifiedExtractor）
- **Domain Layer**: モデル抽象化（ModelExtractorプロトコル）
- **Infrastructure Layer**: 具体的な実装（FoundationModelsExtractor, ExternalLLMExtractor）

### ストラテジーパターン

- **ModelExtractorプロトコル**: FoundationModelsと外部LLMの抽出処理を統一するインターフェース
- **ExtractionMethod**: generable（@Generableマクロ）とjsonの2つの抽出方法
- **ExtractionMode**: simple（単純推定）とtwo-steps（分割推定）の2つの抽出モード

### 非同期処理アーキテクチャ

- **async/await**: モダンな非同期処理パターン
- **@MainActor**: UI更新とモデル抽出のスレッド安全性確保
- **Task**: 並行処理の管理

## 主要コンポーネント

### 1. UnifiedExtractor

**責任**: 統一された抽出フローの管理

**主要機能**:
- 単純推定（simple）と分割推定（two-steps）の切り替え
- プロンプト生成、テストデータ読み込み、抽出処理、メトリクス作成の統一
- モデル抽象化による実装の切り替え

**設計原則**:
- 単一責任の原則: 抽出フローの統括のみに集中
- 開放閉鎖の原則: 新しい抽出モードの追加が容易
- 依存性逆転の原則: ModelExtractorプロトコルに依存

### 2. ModelExtractorプロトコル

**責任**: モデル抽象化レイヤー

**主要機能**:
- FoundationModelsと外部LLMの抽出処理を統一するインターフェース
- モデル固有の実装を抽象化

**実装クラス**:
- **FoundationModelsExtractor**: FoundationModels APIを使用した抽出
- **ExternalLLMExtractor**: 外部LLM（HTTP API）を使用した抽出

### 3. TwoStepsProcessor

**責任**: 2ステップ抽出処理の実装

**主要機能**:
- Step 1: ドキュメントタイプ判定（メインカテゴリ + サブカテゴリ）
- Step 2: サブカテゴリベースのアカウント情報抽出
- カテゴリ定義の読み込みと適用

**設計原則**:
- 単一責任の原則: 2ステップ抽出のみに集中
- 開放閉鎖の原則: 新しいカテゴリの追加が容易

### 4. CommonExtractionProcessor

**責任**: 共通処理の提供

**主要機能**:
- プロンプト生成（method、algo、languageに基づく）
- テストデータ読み込み
- メトリクス作成

**設計原則**:
- DRY原則: コードの重複を排除
- 単一責任の原則: 共通処理のみに集中

### 5. AccountInfo

**責任**: アカウント情報モデル定義

**主要フィールド**:
- `title`: サービス名、アプリ名、サイト名
- `userID`: メールアドレス、ユーザー名、ログインID
- `password`: パスワード文字列
- `url`: ログインページURL、サービスURL
- `note`: 備考、メモ、追加情報
- `host`: ホスト名またはIPアドレス
- `port`: ポート番号
- `authKey`: 認証キー（SSH秘密鍵など）
- `number`: アカウントやカードの識別番号

**特徴**:
- `@Generable`マクロ: FoundationModels特有の型安全な構造化抽出
- `@Guide`マクロ: 各フィールドの説明と制約を定義

### 6. PatternDefinitions

**責任**: 実験パターン定義

**主要定義**:
- **ExtractionMethod**: generable, json
- **ExtractionMode**: simple, two-steps
- **PromptLanguage**: japanese, english
- **InstructionType**: abstract, strict, persona
- **ExperimentPattern**: 実験パターンの列挙型

## 抽出フロー

### 単純推定（Simple Mode）

1. **プロンプト生成**: method、algo、languageに基づいてプロンプトテンプレートを生成
2. **テストデータ読み込み**: testcase、levelに基づいてテストデータを読み込み
3. **プロンプト完成**: プロンプトテンプレートにテストデータを埋め込み
4. **抽出処理**: ModelExtractorを使用してアカウント情報を抽出
5. **メトリクス作成**: 抽出結果からメトリクスを計算

### 分割推定（Two-Steps Mode）

1. **Step 1: ドキュメントタイプ判定**
   - Step 1a: メインカテゴリ判定（work, personal, financial, digital, infra）
   - Step 1b: サブカテゴリ判定（メインカテゴリに基づく）
2. **Step 2: アカウント情報抽出**
   - サブカテゴリに応じた専用プロンプトで抽出
   - サブカテゴリ固有の構造体からAccountInfoに変換

## データモデル

### AccountInfo

```swift
@Generable(description: "サービスのアカウントに関する情報")
public struct AccountInfo: Codable, Identifiable, Sendable {
    @Guide(description: "サービスやシステムの名前または提供者名")
    public var title: String?
    
    @Guide(description: "ログイン用のユーザーIDやメールアドレス")
    public var userID: String?
    
    // ... その他のフィールド
}
```

### ExtractionResult

```swift
public struct ExtractionResult: Sendable {
    public let accountInfo: AccountInfo
    public let rawResponse: String
    public let requestContent: String?
    public let extractionTime: TimeInterval
    public let method: ExtractionMethod
}
```

### ExtractionMetrics

```swift
public struct ExtractionMetrics: Codable, Sendable {
    public let extractionTime: TimeInterval
    public let totalTime: TimeInterval
    // ... その他のメトリクス
}
```

### ContentInfo

```swift
public struct ContentInfo: Codable, Sendable {
    public let mainCategory: String
    public let subCategory: String
}
```

## エラーハンドリング戦略

### 多層防御

1. **入力検証**: 型安全性によるコンパイル時チェック
2. **実行時検証**: assertionによる意図の明示
3. **例外処理**: do-catchによる適切なエラーハンドリング
4. **ログ記録**: LogWrapperによる構造化ログ

### 堅牢性の確保

- 個別テストケースの失敗が全体に影響しない設計
- タイムアウト機能による無限待機の防止
- JSON解析エラーの適切な処理

## 拡張性の考慮

### 新機能追加

1. **新しい抽出方法**: `ExtractionMethod` enumへの追加
2. **新しい抽出モード**: `ExtractionMode` enumへの追加
3. **新しいモデル実装**: `ModelExtractor`プロトコルの実装
4. **新しいカテゴリ**: `CategoryDefinitions`への追加

### プラットフォーム対応

- iOS 26+ (Apple Intelligence要件)
- macOS 26+ (Apple Intelligence要件)
- シミュレーターと実機の両対応

## 実験実行フロー

### コマンドライン実行

```bash
swift run AITestApp \
  --method json \
  --mode two-steps \
  --testcase chat \
  --levels 1 \
  --runs 20 \
  --language ja
```

### Pythonスクリプト実行

```bash
python3 scripts/run_experiments.py \
  --method json \
  --mode two-steps \
  --testcase chat \
  --levels 1 \
  --runs 20 \
  --language ja
```

## ログとレポート

### ログ形式

- **構造化JSONログ**: `{testcase}_{algo}_{method}_{language}_level{level}_run{run#}.json`
- **ログスキーマ**: `docs/LOG_SCHEMA.md`を参照

### レポート生成

- **統合レポート**: `scripts/generate_combined_report.py`
- **HTML形式**: 視覚的な評価のため
- **統計情報**: 正解率、誤り率、欠落率、過剰抽出率

## セキュリティ考慮事項

### データ保護

- テストデータのローカル保存
- 個人情報の非収集
- 認証情報の適切な管理

### プライバシー

- ユーザーデータの最小収集
- 匿名化された統計情報のみ収集

## パフォーマンス最適化

### メモリ管理

- 適切なメモリ解放
- 大きなレスポンスの効率的な処理

### CPU効率

- 非同期処理の活用
- 不要な計算の回避

## テスト戦略

### ユニットテスト

- 個別コンポーネントの動作検証
- エッジケースのテスト
- モックを使用した分離テスト

### 統合テスト

- コンポーネント間の連携テスト
- エンドツーエンドの動作確認

### 実験データ検証

- 期待値との比較
- 統計的な分析
- レポート生成の検証
