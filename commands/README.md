# AIコマンドファイル

このディレクトリには、FoundationModelsの性能評価と実験に関するAIコマンドファイルが格納されています。

## コマンドファイル一覧

### 1. 基礎実験コマンド
- **ファイル**: `benchmark_report_command.md`
- **目的**: FoundationModelsの基本的な性能評価レポート作成
- **実行内容**: 
  - 繰り返しベンチマーク実行
  - 各テストケースのAI回答詳細分析
  - note内容の質的評価
  - 文字レベル精度分析
  - HTMLレポートの修正・加筆

### 2. フォーマット実験コマンド
- **ファイル**: `format_experiment_command.md`
- **目的**: 抽出方法とプロンプト言語の性能比較実験
- **実行内容**:
  - 抽出方法比較（@Generable、JSON、YAML）
  - 言語比較（日本語、英語）
  - エラーパターン分析
  - 性能比較レポート作成

## 使用方法

### 基礎実験の実行
```bash
# コマンドファイルの内容を確認
cat commands/benchmark_report_command.md

# 基礎実験を実行
swift run AITestApp > benchmark_execution.log 2>&1

# ログを確認
cat benchmark_execution.log
```

### フォーマット実験の実行
```bash
# コマンドファイルの内容を確認
cat commands/format_experiment_command.md

# フォーマット実験を実行
swift run AITestApp --test-extraction-methods > format_experiment.log 2>&1

# ログを確認
cat format_experiment.log
```

## ディレクトリ構造

```
commands/
├── README.md                           # このファイル
├── benchmark_report_command.md         # 基礎実験コマンド
└── format_experiment_command.md        # フォーマット実験コマンド
```

## 新しいコマンドファイルの追加

新しい実験やテストを追加する場合は、以下の命名規則に従ってください：

- **命名規則**: `{実験名}_command.md`
- **例**: `accuracy_analysis_command.md`, `performance_optimization_command.md`

## 注意事項

1. **コマンドファイルの独立性**: 各コマンドファイルは独立して実行可能である必要があります
2. **前提条件の明記**: 各コマンドファイルには必要な前提条件を明記してください
3. **実行手順の詳細化**: ステップバイステップの実行手順を記載してください
4. **ログファイルの管理**: 各実験のログファイル名を明確に指定してください

## 更新履歴

- **2024-12-19**: 初回作成
  - `benchmark_report_command.md` を移動
  - `format_experiment_command.md` を移動
  - ディレクトリ構造を整備
