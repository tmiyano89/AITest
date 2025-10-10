## フォーマット実験 実行ログ（2025-10-07）

### 概要（目的・背景・意図）
- 目的: FoundationModelsの抽出方法（@Generable/JSON/YAML）×プロンプト言語（日本語/英語）の性能を再計測し、pendingフィールドのAI検証を反映した統合レポートを生成する。
- 背景: `commands/format_experiment_command.md` に従い、並列実行により全パターンを高速に実行し、最新 `test_logs` に結果を集約する。
- 意図: エラーやデタラメ抽出の傾向を定量化し、改善余地を特定する。

### 実装内容（チェックリスト）
- [x] 並列フォーマット実験を全パターンで実行
- [x] 最新のテストディレクトリ `test_logs/test_202510071801` を特定
- [x] pending項目（title/note）を横断抽出（7件）
- [x] Chat L1/L2の文面と抽出値を照合し、title/note を `correct` に更新
- [x] 統合レポート及び詳細メトリクスを生成
- [x] レポートを起動して目視確認

### 主要結果
- 統合レポート: `test_logs/test_202510071801/parallel_format_experiment_report.html`
- 詳細メトリクス: `test_logs/test_202510071801/detailed_metrics.json`
- 集計サマリ（スクリプト出力）:
  - 総フィールド数: 403
  - 正解率: 51.1%
  - 誤り率: 11.6%
  - 欠落率: 4.5%
  - 過剰抽出率: 48.8%
  - Precision: 0.535 / Recall: 0.919

### 所見（簡潔）
- Chat Level1_Basic における `title`/`note` は文脈的に妥当であり `correct` と判断。
- ログ解析時に一部 `*.log` で UTF-8 読み込みエラーが発生したが、解析は継続し統合レポート生成は成功。
- 過剰抽出率が高く、特に `url/host/port/authKey` の不要抽出が多い。プロンプトの抑制指示とスキーマの厳格化が有効と考える。

### 次のステップ
- Contract/CreditCard/PasswordManager/VoiceRecognition でも pending 残が無いか再確認し、同様の基準で確定させる。
- エンコーディングエラーを再現・特定（ログ生成側の出力整合性/末尾改行/ファイル分割などを調査）。
- プロンプト改善案の試作（不要フィールドの明示禁止、温度/トークン制御、例示の最適化）。


