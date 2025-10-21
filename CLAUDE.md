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
├── Sources/
│   ├── AITest/              # メインライブラリ
│   │   ├── AccountInfo.swift           # アカウント情報モデル定義
│   │   ├── FoundationModelsExtractor.swift  # FoundationModels実装
│   │   ├── ExternalLLMExtractor.swift      # 外部LLM実装
│   │   ├── UnifiedExtractor.swift          # 統一抽出フロー
│   │   ├── ModelExtractor.swift            # モデル抽象化プロトコル
│   │   ├── JSONExtractor.swift             # JSON解析・サニタイズ
│   │   ├── PatternDefinitions.swift        # 実験パターン定義
│   │   └── Prompts/                        # プロンプトテンプレート
│   │       ├── abstract_generable_ja.txt   # 抽象指示（@Generable、日本語）
│   │       ├── abstract_json_ja.txt        # 抽象指示（JSON、日本語）
│   │       ├── strict_generable_ja.txt     # 厳格指示（@Generable、日本語）
│   │       ├── persona_generable_ja.txt    # 人格指示（@Generable、日本語）
│   │       ├── example_ja.txt              # 例示テンプレート（日本語）
│   │       └── *_en.txt                    # 英語版プロンプト
│   └── AITestApp/           # コマンドラインアプリ
│       ├── main.swift                      # エントリーポイント
│       └── TestData/                       # テストデータ
├── Tests/
│   └── AITestTests/         # ユニットテスト
├── commands/                # AI実行用コマンドファイル
│   ├── format_experiment_command.md        # フォーマット実験手順
│   ├── benchmark_report_command.md         # ベンチマーク実験手順
│   └── external_llm_experiment_command.md  # 外部LLM比較実験手順
├── scripts/                 # 実験実行・レポート生成スクリプト
│   ├── run_experiments.py                  # 逐次実験実行
│   ├── parallel_experiment_manager.py      # 並列実験実行
│   ├── generate_combined_report.py         # 統合レポート生成
│   ├── extract_pending_items.py            # pending項目抽出
│   └── update_pending_status.py            # pending項目ステータス更新
├── test_logs/               # 実験ログ出力ディレクトリ
│   ├── yyyymmddhhmm_実験名/                # タイムスタンプ付き実験ディレクトリ
│   └── latest -> ...                       # 最新実験へのシンボリックリンク
├── reports/                 # 最終レポート格納ディレクトリ
│   └── final_format_experiment_report_*.html
├── docs/                    # プロジェクトドキュメント
│   ├── EXPERIMENT_PATTERNS.md              # 実験パターン仕様
│   ├── LOG_SCHEMA.md                       # ログスキーマ定義
│   ├── ARCHITECTURE.md                     # アーキテクチャ設計
│   └── ai-logs/                            # AI開発ログ
├── Package.swift            # Swift Package定義
└── README.md                # プロジェクトREADME
```

## コアコンセプト

### 1. 実験パターン（Experiment Patterns）

このプロジェクトでは、以下の軸で実験パターンを定義しています：

#### 指示タイプ（Instruction Type）

- **抽象指示（abstract）**: 最小限の指示でAIの創造性を最大限発揮
- **厳格指示（strict）**: 詳細な制約ルールで出力品質を向上
- **人格指示（persona）**: 専門家の役割を設定して関連知識を活性化

#### 例示の有無（Has Example）

- **例示なし**: 基本性能の測定
- **例示あり（-ex）**: few-shot学習による性能向上効果の測定

#### 抽出方法（Extraction Method）

- **@Generable（generable）**: FoundationModels特有の型安全な構造化抽出
- **JSON（json）**: テキストベースの構造化抽出（外部LLM互換）

#### アルゴリズム識別子（Algo）

パターン命名規則: `{testcase}_{algo}_{method}_{language}_{level}_{run#}.json`

例:
- `abs`: 抽象指示のみ
- `abs-ex`: 抽象指示+例示
- `strict`: 厳格指示のみ
- `strict-ex`: 厳格指示+例示
- `persona`: 人格指示のみ
- `persona-ex`: 人格指示+例示

### 2. テストレベル（Test Levels）

- **Level 1**: 基本的なアカウント情報（チャット、パスワード等）
- **Level 2**: 中程度の複雑さ（クレジットカード等）
- **Level 3**: 高度な情報（契約情報等）

### 3. 実験フロー

```
1. 実験実行 (Swift/Python)
   ↓
2. 構造化JSONログ出力 (test_logs/)
   ↓
3. レポート生成 (HTML)
   ↓
4. pending項目の手動検証
   ↓
5. ステータス更新
   ↓
6. レポート再生成
   ↓
7. 最終分析・考察（AI手動分析）
```

## 実験の実行方法

### 実行原則

実験の具体的な手順は`commands/`ディレクトリの各コマンドファイルに記載されています。AIアシスタントがこれらのファイルを読み込んで自動実行できるようになっています。

**主要な実行方法：**

1. **Pythonスクリプトによる実験実行**: `scripts/run_experiments.py`（逐次）、`scripts/parallel_experiment_manager.py`（並列・推奨）
2. **AITestAppによる直接実行**: デバッグ・単体テスト用（`swift run AITestApp`）
3. **外部LLM実験**: FoundationModelsとの比較のため、AI部分のみを外部LLMに置き換えて実験

**実験フロー:**
```
コマンドファイル参照 → 実験実行 → JSONログ出力 → レポート生成 → 検証・分析
```

### 利用可能なコマンドファイル

各実験の詳細な手順については、以下のコマンドファイルを参照してください：

- `commands/format_experiment_command.md`: フォーマット実験の完全な手順
- `commands/benchmark_report_command.md`: ベンチマーク実験の手順
- `commands/external_llm_experiment_command.md`: 外部LLM比較実験の手順

**使用例:**
```
AIに「commands/format_experiment_command.mdに従ってフォーマット実験を実行してください」と指示
```

## プロンプトのチューニング

### プロンプトテンプレートの配置

プロンプトテンプレートは`Sources/AITest/Prompts/`に配置されており、以下の命名規則に従います：

```
{instruction_type}_{method}_{language}.txt
```

例:
- `abstract_generable_ja.txt`: 抽象指示、@Generable、日本語
- `strict_json_en.txt`: 厳格指示、JSON、英語
- `persona_generable_ja.txt`: 人格指示、@Generable、日本語

### 例示テンプレート

例示は専用のテンプレートファイルで管理：

- `example_ja.txt`: 日本語の例示
- `example_en.txt`: 英語の例示

### プロンプト編集時の注意事項

1. **ファイルベースでの管理**: プロンプトはすべてファイルで管理されているため、変更は該当ファイルを直接編集
2. **命名規則の遵守**: 新しいプロンプトを追加する場合は命名規則に従うこと
3. **言語の統一**: 日本語（ja）と英語（en）の両方を用意すること
4. **再ビルド不要**: プロンプトファイルはリソースとして扱われるため、変更後はビルド不要で即座に反映

## レポート生成と分析

### レポート生成の原則

実験実行後、`scripts/generate_combined_report.py`を使ってHTMLレポートを生成します。レポートには以下の性能指標が含まれます：

**主要指標:**
- **正規化スコア**: 各パターンの総合評価指標((正解項目数-誤り項目数-欠落項目数)/期待項目数)
- **正解率**: 期待される項目が正しく抽出された割合
- **誤り率**: 抽出された項目の値が間違っている割合
- **欠落率**: 期待される項目が抽出されなかった割合
- **過剰抽出率**: 期待されない項目が誤って抽出された割合

**詳細分析:**
- レベル別性能（Level 1/2/3）
- Algo別性能（abs、strict、persona等）
- 詳細実行ログ

### pending項目の手動検証

実験後、ルールベースでは正誤判定できない項目（pending）はAIが内容を直接確認して検証する必要があります。

**検証原則:**

1. **抽出**: `scripts/extract_pending_items.py`で該当項目をCSV形式で抽出
2. **手動検証**: テストデータと照らし合わせて意味的整合性を判断
   - ⚠️ **重要**: 検索や正規表現による一括処理は禁止。各項目を個別に確認すること
3. **CSV作成**: 検証結果をコンパクトCSV形式で記録
4. **ステータス更新**: `scripts/update_pending_status.py`でJSONログを一括更新
5. **レポート再生成**: 更新後のレポートを再生成して精度を再評価

**詳細手順**: `commands/format_experiment_command.md`の「pending項目のAI検証と更新」セクションを参照

## 過去の実験履歴

このセクションには、過去に実施した実験の記録を時系列で記載します。各実験には対応するコマンドファイルと結果レポートへのリンクを含めます。

### 2024-12-19: プロジェクト初期セットアップ

- **目的**: FoundationModels APIを使ったアカウント情報抽出の基本実装
- **開発ログ**: `docs/ai-logs/2024-12-19-project-setup.md`

### 2024-12-19: ベンチマーク実験

- **目的**: FoundationModelsの基本的な性能評価レポート作成
- **コマンドファイル**: `commands/benchmark_report_command.md`
- **結果レポート**:
  - `reports/benchmark_report.html`
  - `reports/final_benchmark_report.html`
- **開発ログ**: `docs/ai-logs/2024-12-19-benchmark-analysis.md`

### 2024-12-19: フォーマット実験（初回）

- **目的**: 抽出方法とプロンプト言語の性能比較実験
- **コマンドファイル**: `commands/format_experiment_command.md`
- **結果レポート**: `reports/format_experiment_report.html`
- **開発ログ**: `docs/ai-logs/2024-12-19-format-experiment.md`

### 2025-10-07: 外部LLM比較実験

- **目的**: FoundationModels vs 外部LLM（gpt-oss-20b）の性能比較
- **コマンドファイル**: `commands/external_llm_experiment_command.md`
- **開発ログ**: `docs/ai-logs/2025-10-07-format-experiment-run.md`

### 2025-10-21: 2ステップ抽出手法の設計

- **目的**: 新しい抽出アプローチの提案と設計
- **開発ログ**: `docs/ai-logs/2025-10-21-two-steps-extraction-design.md`

---

**新しい実験を追加する際**: このセクションに日付、目的、コマンドファイル、結果レポートへのリンクを追加してください。

## 開発ガイドライン

### コーディング規約

1. **Swift 6.0の厳格モード**: Sendable、actor分離、データ競合チェックを遵守
2. **@aiアノテーション**: すべての重要な変更にアノテーションを付与
   ```swift
   /// @ai[2025-01-18 12:05] 抽出方法の定義
   /// 目的: アカウント情報抽出の方法を型安全に管理
   /// 背景: @Generable、JSON、YAMLの3つの方法を統一
   /// 意図: 各方法の特徴を明確化し、プロンプト生成を最適化
   ```
3. **型安全性**: できる限り型安全な設計を優先
4. **ファイル命名規則**:
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

### 実験実行エラー

```bash
# デバッグモードで単一実験実行
swift run AITestApp --debug-single --method json --testcase chat --language ja

# プロンプト内容の確認
swift run AITestApp --debug-prompt --method json --testcase chat --language ja
```

### レポート生成エラー

```bash
# ログファイルの構造を確認
cat test_logs/latest/*.json | head -50

# Pythonスクリプトの詳細ログ
python3 scripts/generate_combined_report.py test_logs/latest --verbose
```

## 参考資料

### プロジェクト内ドキュメント

- `README.md`: プロジェクト概要と基本情報
- `docs/EXPERIMENT_PATTERNS.md`: 実験パターンの詳細仕様
- `docs/LOG_SCHEMA.md`: ログスキーマの詳細定義
- `docs/ARCHITECTURE.md`: アーキテクチャ設計ドキュメント
- `docs/ai-logs/`: AI開発ログ（日付別）

### 主要ソースファイル

- `Sources/AITest/FoundationModelsExtractor.swift`: FoundationModels抽出実装
- `Sources/AITest/UnifiedExtractor.swift`: 統一抽出フロー
- `Sources/AITest/PatternDefinitions.swift`: 実験パターン定義
- `Sources/AITestApp/main.swift`: コマンドラインアプリエントリーポイント

---

**最終更新**: 2025-10-21
**プロジェクトバージョン**: iOS 26+ / macOS 26+
**Swift Version**: 6.0+

## 新しい実験を追加する場合の手順

1. `commands/`ディレクトリに新しいコマンドファイル（`{実験名}_command.md`）を作成
2. 実験を実行し、結果をJSONログとして`test_logs/`に出力
3. `scripts/generate_combined_report.py`でHTMLレポートを生成
4. 最終レポートを`reports/`に保存
5. このCLAUDE.mdの「過去の実験履歴」セクションに記録を追加
