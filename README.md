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
└── scripts/                  # ビルド・デプロイスクリプト
```

### 性能測定項目
1. **推論時間**: 各モデルの推論実行時間
2. **メモリ使用量**: モデル読み込み時・推論時のメモリ消費
3. **CPU使用率**: 推論処理中のCPU負荷
4. **バッテリー消費**: 実機での電力消費測定
5. **スループット**: 連続推論時の処理能力

### 使用方法
1. Xcodeでプロジェクトを開く
2. シミュレーターまたは実機を選択
3. アプリを実行し、性能測定を開始
4. 結果はCSV形式でエクスポート可能

## ライセンス
MIT License
