# レポートファイル

このディレクトリには、FoundationModelsの性能評価と実験に関するHTMLレポートファイルが格納されています。

## レポートファイル一覧

### 基礎実験レポート
- **ファイル**: `benchmark_report.html`
- **生成元**: `commands/benchmark_report_command.md`
- **内容**: FoundationModelsの基本的な性能評価レポート
- **生成方法**: `swift run AITestApp > benchmark_execution.log 2>&1`

### 拡張レポート
- **ファイル**: `enhanced_benchmark_report.html`
- **生成元**: `commands/benchmark_report_command.md`（手動編集版）
- **内容**: 基礎実験レポートに詳細分析を追加した拡張版

### 最終レポート
- **ファイル**: `final_benchmark_report.html`
- **生成元**: `commands/benchmark_report_command.md`（最終版）
- **内容**: すべての分析結果を統合した最終レポート

## ディレクトリ構造

```
reports/
├── README.md                           # このファイル
├── benchmark_report.html               # 基礎実験レポート（自動生成）
├── enhanced_benchmark_report.html      # 拡張レポート（手動編集）
└── final_benchmark_report.html         # 最終レポート
```

## レポートの生成

### 基礎実験レポートの生成
```bash
# ベンチマーク実行
swift run AITestApp > benchmark_execution.log 2>&1

# レポート確認
open reports/benchmark_report.html
```

### フォーマット実験レポートの生成
```bash
# フォーマット実験実行
swift run AITestApp --test-extraction-methods > format_experiment.log 2>&1

# レポート確認（生成後）
open reports/format_experiment_report.html
```

## ファイル命名規則

- **基礎実験**: `benchmark_report.html`
- **フォーマット実験**: `format_experiment_report.html`
- **拡張版**: `enhanced_{実験名}_report.html`
- **最終版**: `final_{実験名}_report.html`

## 注意事項

1. **レポートの独立性**: 各レポートは独立して閲覧可能である必要があります
2. **相対パスの使用**: レポート内のリンクは相対パスを使用してください
3. **ファイルサイズの管理**: 大きなレポートファイルは適切に圧縮してください
4. **バックアップ**: 重要なレポートは適切にバックアップしてください

## 更新履歴

- **2024-12-19**: 初回作成
  - HTMLレポートファイルを移動
  - ディレクトリ構造を整備
  - 命名規則を確立
