# AITest - iOS26 Apple Intelligence Foundation Model Performance Validation

## プロジェクト概要

このプロジェクトは、iOS26のApple Intelligence Foundation Modelの性能を数値的に評価・検証するためのiOSアプリケーションです。

### 目的
- Apple Intelligence Foundation Modelの推論性能の測定
- メモリ使用量、CPU使用率、推論時間の詳細分析
- シミュレーターと実機での性能比較
- 異なるモデルサイズ・設定での性能評価

### 開発環境
- **開発マシン**: MacBook Pro (Apple M4)
- **対象OS**: iOS 26
- **開発言語**: Swift 6.0+
- **フレームワーク**: SwiftUI, Core ML, Apple Intelligence

### プロジェクト構成
```
AITest/
├── AITest/                    # iOSアプリケーション
├── AITestTests/              # ユニットテスト
├── AITestUITests/            # UIテスト
├── Benchmark/                # 性能測定フレームワーク
├── docs/                     # ドキュメント
│   └── ai-logs/             # AI開発ログ
├── scripts/                  # ビルド・デプロイスクリプト
└── test_logs/                # 実験データ保存ディレクトリ
    └── yyyymmddhhmm_実験名/  # 実験ごとのタイムスタンプ付きディレクトリ
```

### 実験データ管理

#### ディレクトリ命名規則
実験データは以下の命名規則で保存されます：
```
test_logs/yyyymmddhhmm_実験名/
```

**例:**
- `test_logs/202501171030_format_experiment/` - 2025年1月17日10:30のformat_experiment
- `test_logs/202501171031_benchmark_test/` - 2025年1月17日10:31のbenchmark_test
- `test_logs/202501171032_generable_ja/` - 2025年1月17日10:32のgenerable_ja実験

#### 保存されるファイル
各実験ディレクトリには以下のファイルが保存されます：
- `{method}_{language}_{pattern}_level{level}_{iteration}.json` - 構造化ログファイル
- `{method}_{language}_format_experiment_report.html` - HTMLレポート
- `detailed_metrics.json` - 詳細メトリクス（集計時）

### 性能測定項目

#### 一般性能測定
1. **推論時間**: 各モデルの推論実行時間
2. **メモリ使用量**: モデル読み込み時・推論時のメモリ消費
3. **CPU使用率**: 推論処理中のCPU負荷
4. **バッテリー消費**: 実機での電力消費測定
5. **スループット**: 連続推論時の処理能力

#### Account情報抽出性能測定
1. **抽出精度**: テキスト・画像からAccount情報を正確に抽出できるか
2. **処理時間**: OCR処理時間 + AI抽出時間の詳細分析
3. **メモリ効率**: 画像処理とAI推論のメモリ使用量
4. **信頼度スコア**: 抽出結果の自己評価精度
5. **フィールド抽出率**: 各Account情報フィールドの抽出成功率

### 使用方法
1. Xcodeでプロジェクトを開く
2. シミュレーターまたは実機を選択
3. アプリを実行し、性能測定を開始
4. **ベンチマークタイプ選択**:
   - **一般性能**: 基本的なAI推論性能測定
   - **Account抽出**: FoundationModelsを使用したAccount情報抽出性能測定
5. 結果はCSV形式でエクスポート可能

### Account情報抽出機能
- **テキスト抽出**: プレーンテキストからAccount情報を抽出
- **画像抽出**: OCR + AI抽出の組み合わせで画像からAccount情報を抽出
- **抽出フィールド**: サービス名、ユーザーID、パスワード、URL、ホスト、ポート、認証キー、備考
- **バリデーション**: 抽出結果の妥当性を自動検証
- **性能測定**: 抽出時間、メモリ使用量、信頼度スコアを詳細測定

### 実験パターン
- **8つの実験パターン**: 抽象/厳格/人格指示 × 例示有無 × ステップ数 × @Generable有無
- **詳細仕様**: [実験パターン仕様書](docs/EXPERIMENT_PATTERNS.md)
- **クイックリファレンス**: [パターン一覧表](docs/PATTERN_QUICK_REFERENCE.md)

## ライセンス
MIT License
