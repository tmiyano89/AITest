# 外部LLMサーバー(RTX6000)接続・利用ガイド

## 概要

本ドキュメントでは、外部LLMサーバー(RTX6000)への接続方法、サービス稼働確認、およびOpenAI互換APIエンドポイントの利用方法について説明します。

## サーバー情報

### 基本情報
- **サーバー名**: slsv25gpu-02 (RTX6000)
- **IPアドレス**: 182.171.83.172
- **SSHポート**: 22172
- **ユーザー**: randduser
- **OS**: Ubuntu 24.04.2 LTS

### ハードウェア仕様
- **GPU**: NVIDIA RTX PRO 6000 Black (98GB VRAM)
- **CUDA**: 12.9
- **Compute Capability**: 12.0
- **メモリ**: 大容量RAM（詳細要確認）

### モデル情報
- **モデル名**: gpt-oss-120b-ggml-org
- **提供元**: ggml-org
- **形式**: GGUF (gpt-oss-120b-mxfp4-00001-of-00003.gguf)
- **パラメータ数**: 116.83B（実測）
- **モデルサイズ**: 59.02 GiB
- **サービス名**: gpt-oss-120b-ggml-org.service
- **API互換性**: OpenAI互換API完全対応

## 1. SSH接続方法

### 基本的な接続コマンド

```bash
ssh rtx6000
```

## 2. サービス稼働確認

### gpt-oss-120bサービスの状態確認

```bash
# サービス状態の確認
ssh rtx6000 "systemctl status gpt-oss-120b-ggml-org"

# サービスが稼働している場合の出力例
# ● gpt-oss-120b-ggml-org.service - GPT OSS 120B GGML Service
#    Loaded: loaded (/etc/systemd/system/gpt-oss-120b-ggml-org.service; enabled; vendor preset: enabled)
#    Active: active (running) since [日時]
```


## 3. APIエンドポイント利用方法

### 基本的な接続テスト

```bash
curl http://182.171.83.172/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer EMPTY" \
  -d '{
    "model": "gpt-oss-120b",
    "messages": [
      {"role": "user", "content": "外部疎通テスト：120Bモデルの性能を3行で説明"}
    ]
  }'
```

### 詳細なAPIリクエスト例

#### 基本的なチャット完了リクエスト

```bash
curl -X POST http://182.171.83.172/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer EMPTY" \
  -d '{
    "model": "gpt-oss-120b",
    "messages": [
      {"role": "system", "content": "あなたは有用なアシスタントです。"},
      {"role": "user", "content": "こんにちは、今日の天気について教えてください。"}
    ],
    "max_tokens": 1000,
    "temperature": 1.0,
    "top_p": 1.0
  }'
```


## 8. 性能ベンチマーク情報

### 実測性能指標（RTX 6000環境）

#### 基本性能
- **プロンプト処理速度**: 5,136 t/s（Flash Attention有効時）
- **トークン生成速度**: 219.71 t/s（Flash Attention有効時）
- **コンテキストサイズ**: 4096トークン
- **最大予測トークン**: 2048トークン
- **GPU使用量**: 59.02 GiB VRAM（実測）

#### 推奨設定
- **Flash Attention**: 有効（`-fa 1`）で約6.5%性能向上
- **温度パラメータ**: 1.0
- **Top-p**: 1.0
- **GPUレイヤー**: 999（全レイヤーでGPU使用）


## 9. レスポンスフォーマット構造

### 概要

gpt-oss-120b-ggml-orgモデルは`--jinja`オプションにより、**分離された思考プロセス**を持つ改良された出力形式を採用しています。

### 基本レスポンス構造

```json
{
  "choices": [
    {
      "finish_reason": "stop|length",
      "index": 0,
      "message": {
        "role": "assistant",
        "reasoning_content": "[内部思考プロセス - 英語]",
        "content": "[最終回答 - 適切な言語]"
      }
    }
  ],
  "created": 1761251091,
  "model": "gpt-oss-120b",
  "system_fingerprint": "b6458-40be5115",
  "object": "chat.completion",
  "usage": {
    "completion_tokens": 200,
    "prompt_tokens": 80,
    "total_tokens": 280
  },
  "id": "chatcmpl-xxx",
  "timings": {
    "cache_n": 0,
    "prompt_n": 80,
    "prompt_ms": 148.317,
    "prompt_per_token_ms": 1.854,
    "prompt_per_second": 539.39,
    "predicted_n": 200,
    "predicted_ms": 957.391,
    "predicted_per_token_ms": 4.787,
    "predicted_per_second": 208.90
  }
}
```

### フィールド仕様

#### 1. **choices[0].message.reasoning_content**
- **型**: `string`
- **内容**: モデルの内部思考プロセス
- **言語**: 英語（固定）
- **用途**: デバッグ、分析、思考プロセスの理解
- **例**: "The user asks in Japanese: 'こんにちは...' meaning 'Hello...' We need to answer in Japanese..."

#### 2. **choices[0].message.content**
- **型**: `string`
- **内容**: 最終的な回答
- **言語**: ユーザーの入力言語に応じて適切な言語
- **用途**: 実際の回答として使用
- **例**: "こんにちは！私は **ChatGPT** と呼ばれる対話型AIです..."

#### 3. **choices[0].finish_reason**
- **型**: `string`
- **可能な値**:
  - `"stop"`: 自然な終了
  - `"length"`: max_tokens制限に達した
- **用途**: 回答の完了状態の判定

#### 4. **usage**
- **completion_tokens**: 生成されたトークン数
- **prompt_tokens**: プロンプトのトークン数
- **total_tokens**: 合計トークン数

#### 5. **timings**
- **prompt_per_second**: プロンプト処理速度（t/s）
- **predicted_per_second**: 生成速度（t/s）
- **cache_n**: キャッシュヒット数

### フォーマットの特徴

#### 1. **分離された思考プロセス**
- 内部思考と最終回答が明確に分離
- JSON構造が標準的で解析しやすい

#### 2. **言語適応**
- `reasoning_content`: 常に英語
- `content`: ユーザーの入力言語に応じて適切な言語で回答

#### 3. **構造化データ対応**
- JSON形式の要求に対して正確なJSONを生成


### 実装時の考慮事項

#### 1. **フィールドアクセス**
- `reasoning_content`はオプショナル（存在しない場合がある）
- `content`は必須フィールド

## 10. 参考情報

### 関連ドキュメント

- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Llama.cpp Server Documentation](https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md)
- [GPT-OSS-120B詳細ガイド](https://github.com/ggml-org/llama.cpp/discussions/15396)

### 設定ファイルの場所

```bash
# サービス設定ファイル
/etc/systemd/system/gpt-oss-120b-ggml-org.service

# モデルファイル
/home/randduser/models/gpt-oss-120b-ggml-org/gpt-oss-120b-mxfp4-00001-of-00003.gguf

# nginx設定
/etc/nginx/sites-available/gpt-oss-120b-ggml-org
```

---
