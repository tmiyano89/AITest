# CLAUDE.md - AITest プロジェクトガイド

## プロジェクト概要

**AITest** は、iOS/macOS（iOS 26+/macOS 26+）でFoundationModels APIを利用したアカウント情報抽出の実験・評価を行うプロジェクトです。主な目的は以下の通りです：

- **@Generable/@Guideマクロのチューニング**: FoundationModels特有のマクロの最適な使用方法を実験的に検証
- **プロンプトのチューニング**: 抽象指示、厳格指示、人格指示などの指示スタイルと例示の有無による性能比較
- **抽出方法の提案**: @Generable（型安全）、JSONフォーマットでの抽出精度と性能の比較
- **FoundationModels vs 外部LLM**: AI部分のみを置き換えて性能を客観的に比較

### 技術スタック

- **言語**: Swift 6.0+
- **プラットフォーム**: iOS 26+, macOS 26+
- **フレームワーク**: FoundationModels API (Apple Intelligence)
- **実験スクリプト**: Python 3
- **レポート形式**: HTML（視覚的評価のため）

## プロジェクト構造

```
AITest/
├── Sources/AITest/                      # メインライブラリ
│   ├── UnifiedExtractor.swift          # 統一抽出フロー（単純推定・2ステップ抽出）
│   ├── TwoStepsProcessor.swift          # 2ステップ抽出処理
│   ├── FoundationModelsExtractor.swift  # FoundationModels実装
│   ├── ExternalLLMExtractor.swift      # 外部LLM実装
│   ├── CategoryDefinitionLoader.swift   # カテゴリ定義読み込み・動的プロンプト生成
│   ├── Prompts/                         # プロンプトテンプレート（単純推定用）
│   └── CategoryDefinitions/             # カテゴリ定義（2ステップ抽出用）
│       ├── category_definitions.json
│       └── subcategories/*.json        # サブカテゴリ定義（25ファイル）
├── Sources/AITestApp/main.swift         # コマンドラインアプリ
├── Tests/TestData/                      # テストデータ（5パターン × 3レベル）
├── scripts/                             # 実験実行・レポート生成スクリプト
├── test_logs/                           # 実験ログ出力ディレクトリ
├── reports/                              # 最終レポート格納ディレクトリ
├── docs/                                 # プロジェクトドキュメント
├── commands/                             # AI実行用コマンドファイル
├── Package.swift                         # Swift Package定義
└── README.md                             # プロジェクトREADME
```

## 開発ガイドライン

### コーディング規約

1. **Swift 6.0の厳格モード**: Sendable、actor分離、データ競合チェックを遵守
2. **@aiアノテーション**: コメントにはアノテーションを付与し、コードの一部として修正・変更の対象とする
   ```swift
   /// @ai[2025-01-18 12:05] 抽出方法の定義
   /// 目的: アカウント情報抽出の方法を型安全に管理
   /// 背景: @Generable、JSON、YAMLの3つの方法を統一
   /// 意図: 各方法の特徴を明確化し、プロンプト生成を最適化
   ```
4. **型安全性**: できる限り型安全な設計を優先
5. **ファイル命名規則**:
   - Swift: PascalCase（例: `FoundationModelsExtractor.swift`）
   - Python: snake_case（例: `run_experiments.py`）
   - ログ: `{testcase}_{algo}_{method}_{lang}_{level}_{run#}.json`

### 新しい実験パターンの追加

1. `Sources/AITest/PatternDefinitions.swift`に新しいパターンを追加
2. `Sources/AITest/Prompts/`に対応するプロンプトテンプレートを追加
3. `docs/EXPERIMENT_PATTERNS.md`にパターンのドキュメントを追加
4. 実験を実行してレポートを生成

### ステータス定義

- **correct**: 正しく抽出された
- **wrong**: 抽出されたが値が間違っている
- **missing**: 期待される項目が抽出されていない
- **excess**: 期待されない項目が誤って抽出された
- **pending**: AIが自信を持てず、人間による検証が必要

## トラブルシューティング

### ビルドエラー

```bash
# クリーンビルド
swift package clean
swift build

# Xcodeでの確認
open Package.swift
```

## AIコマンド
[AIコマンド]の指示を実行された場合、以下の手順で実行すること

1. `commands/`ディレクトリのコマンドファイル（`{実験名}_command.md`）から対象のファイルを読み込む
2. コマンドファイルに従って処理を逐次的に最後まで実行する
