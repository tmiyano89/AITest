# AIコマンド: 外部LLM性能比較実験

## 概要
FoundationModelsと外部ローカルLLM（gpt-oss-20b）の性能比較実験を実行し、客観的な評価データを収集します。

## 1. 外部LLM実験の実行

### 1.1 基本的な実行方法
```bash
# 外部LLM実験を実行（デフォルト設定）
python3 scripts/run_external_llm_experiment.py \
  --external-llm-url "http://182.171.83.172" \
  --external-llm-model "openai/gpt-oss-20b" \
  --patterns chat_abs_json chat_persona_json chat_strict_json \
  --runs 20 \
  --generate-report
```

### 1.2 パラメータ説明
- `--external-llm-url`: 外部LLMサーバーのベースURL
- `--external-llm-model`: 使用するLLMモデル名
- `--patterns`: 実行するパターン（JSON形式のみ）
- `--runs`: 各パターンの実行回数（デフォルト: 20）
- `--generate-report`: 実験後にHTMLレポートを生成

### 1.3 利用可能なパターン
- `chat_abs_json`: Chat・抽象指示・JSON
- `chat_persona_json`: Chat・人格指示・JSON
- `chat_strict_json`: Chat・厳格指示・JSON
- `chat_twosteps_json`: Chat・2ステップ・JSON
- `chat_abs-ex_json`: Chat・抽象指示+例示・JSON
- `chat_persona-ex_json`: Chat・人格指示+例示・JSON
- `chat_strict-ex_json`: Chat・厳格指示+例示・JSON

## 2. 実験結果の確認

### 2.1 ログファイルの場所
```
test_logs/yyyymmddhhmm_external_llm_experiment/
├── chat_abs_json_ja_level1_run1.json
├── chat_abs_json_ja_level2_run1.json
├── chat_abs_json_ja_level3_run1.json
├── ...
└── external_llm_report.html
```

### 2.2 レポートの表示
```bash
# 生成されたレポートを表示
open test_logs/yyyymmddhhmm_external_llm_experiment/external_llm_report.html
```

## 3. FoundationModelsとの比較

### 3.1 比較実験の実行
```bash
# FoundationModels実験（既存）
python3 scripts/run_experiments.py \
  --patterns chat_abs_json chat_persona_json chat_strict_json \
  --runs 20 \
  --output-dir test_logs/yyyymmddhhmm_foundation_models

# 外部LLM実験
python3 scripts/run_external_llm_experiment.py \
  --external-llm-url "http://182.171.83.172" \
  --external-llm-model "openai/gpt-oss-20b" \
  --patterns chat_abs_json chat_persona_json chat_strict_json \
  --runs 20 \
  --generate-report
```

### 3.2 比較レポートの生成
```bash
# 両方の結果を比較するレポートを生成
python3 scripts/generate_comparison_report.py \
  --foundation-models-dir test_logs/yyyymmddhhmm_foundation_models \
  --external-llm-dir test_logs/yyyymmddhhmm_external_llm_experiment \
  --output comparison_report.html
```

## 4. 期待される結果

### 4.1 性能指標
- **正規化スコア**: 抽出精度の総合評価
- **抽出時間**: レスポンス時間の比較
- **正解率**: 期待項目の正確な抽出率
- **ハルシネーション率**: 過剰抽出の発生率

### 4.2 分析観点
1. **精度比較**: FoundationModels vs 外部LLM
2. **速度比較**: 処理時間の差
3. **パターン別性能**: 各指示方法での性能差
4. **レベル別性能**: 複雑度による性能変化

## 5. トラブルシューティング

### 5.1 外部LLM接続エラー
```bash
# 接続テスト
curl -s http://182.171.83.172/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer EMPTY" \
  -d '{"model": "openai/gpt-oss-20b", "messages": [{"role":"user", "content":"test"}]}'
```

### 5.2 タイムアウトエラー
- 外部LLMサーバーの負荷を確認
- `--runs` パラメータを減らして実行
- ネットワーク接続を確認

### 5.3 メモリ不足
- 同時実行数を制限
- システムリソースを確認

## 6. 参考ファイル

- `scripts/run_external_llm_experiment.py`: 外部LLM実験実行スクリプト
- `Sources/AITest/ExternalLLMClient.swift`: 外部LLM通信クライアント
- `Sources/AITest/AccountExtractor.swift`: 抽出器（外部LLM対応）
- `scripts/generate_combined_report.py`: レポート生成スクリプト
- `test_logs/`: 実験結果ディレクトリ

## 7. 注意事項

- 外部LLMサーバーが利用可能であることを確認
- ネットワーク接続が安定していることを確認
- 実験結果は適切にバックアップを取る
- 大量の実験実行時はサーバー負荷に注意
