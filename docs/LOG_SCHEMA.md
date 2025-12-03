# AITestApp ログスキーマ定義

## ドキュメント情報

- **最終更新**: 2025-12-03 16:41
- **バージョン**: 2.0
- **対象実装**: iOS 26+, macOS 26+

## 概要
AITestAppが出力する構造化JSONログのスキーマ定義です。このスキーマに基づいてログの解析とAI検証を行います。

## ログファイル形式

### ファイル名
```
{testcase}_{algo}_{method}_{language}_level{level}_run{runNumber}.json
```

**ファイル名の構成要素**:
- `testcase`: テストケース名（chat, contract, creditcard, password, voice）
- `algo`: アルゴリズム（abs, strict, persona, abs-ex, strict-ex, persona-ex）
- `method`: 抽出方法（generable, json）
- `language`: 言語（ja, en）
- `level`: レベル（1, 2, 3）
- `runNumber`: 実行回数（1, 2, 3, ...）

例：
- `chat_strict_json_ja_level1_run1.json`
- `chat_abs_generable_ja_level2_run5.json`
- `chat_strict_json_ja_level3_run16_error.json`（エラー時）

**注意**: YAMLサポートは削除されました。`method`は`generable`または`json`のみです。

### JSONスキーマ

#### 基本構造（正常時）
```json
{
  "pattern": "string",              // テストパターン (Chat, Contract, CreditCard, VoiceRecognition, PasswordManager)
  "level": number,                  // レベル (1, 2, 3)
  "iteration": number,              // 繰り返し回数 (1, 2, 3, ...)
  "method": "string",               // 抽出方法 (generable, json)
  "language": "string",             // 言語 (ja, en)
  "experiment_pattern": "string",   // 実験パターン (abs_gen, strict_json, persona-ex_json など)
  "request_content": "string|null", // リクエスト内容（プロンプトやAIレスポンスなど、nullの場合は未設定）
  "expected_fields": [              // 期待されるフィールドの配列(抽出すべき項目をすべて記載すること)
    {
      "name": "string",             // フィールド名 (title, userID, password, url, note, host, port, authKey)
      "value": "string|null",       // 抽出された値 (nullの場合は未抽出)
      "status": "string"            // ステータス (correct, wrong, missing, pending)
    }
  ],
  "unexpected_fields": [            // 期待されないフィールドの配列(実際に抽出された項目のみ記載すること)
    {
      "name": "string",             // フィールド名
      "value": "string",             // 抽出された値
      "status": "unexpected"        // 常に"unexpected"
    }
  ],
  "two_steps_category": {           // 2ステップ抽出時のみ存在（オプション）
    "main_category": "string",      // メインカテゴリID (work, financial, digital, personal, infrastructure)
    "main_category_display": "string", // メインカテゴリ表示名（日本語）
    "sub_category": "string",       // サブカテゴリID (workServer, financialCreditCard など)
    "sub_category_display": "string"  // サブカテゴリ表示名（日本語）
  },
  "error": null                     // エラーメッセージ (エラーがない場合はnull)
}
```

#### エラー時の構造
```json
{
  "pattern": "string",              // テストパターン
  "level": number,                  // レベル
  "iteration": number,              // 繰り返し回数
  "method": "string",               // 抽出方法
  "language": "string",             // 言語
  "experiment_pattern": "string",   // 実験パターン
  "request_content": "string|null", // リクエスト内容
  "error": "string",                // エラーメッセージ（必須）
  "error_type": "string",           // エラーの型（例: "ExtractionError"）
  "ai_response": "string|null",     // AIレスポンス（エラー時にAIレスポンスがある場合のみ）
  "expected_fields": [               // 期待されるフィールド（すべてmissingとして記録）
    {
      "name": "string",
      "value": null,
      "status": "missing"
    }
  ],
  "unexpected_fields": []           // エラー時は空配列
}
```

## ステータス定義

### expected_fieldsのstatus
- **correct**: 正しく抽出された（期待値と完全一致）
- **wrong**: 抽出されたが値が間違っている（期待値と不一致）
- **missing**: 抽出されなかった（値がnullまたは空文字列）
- **pending**: AIによる検証が必要（title、noteのみ。自由形式の記述が可能なため）

**注意**: `unexpected`は`expected_fields`には使用されません。期待されない項目は`unexpected_fields`に記録されます。

### unexpected_fieldsのstatus
- **unexpected**: 期待されない項目が抽出された（常にこの値）

## フィールドの詳細説明

### 基本フィールド

| フィールド | 型 | 説明 | 必須 |
|-----------|-----|------|------|
| `pattern` | string | テストパターン名（大文字始まり: Chat, Contract, CreditCard, VoiceRecognition, PasswordManager） | 必須 |
| `level` | number | テストレベル（1, 2, 3） | 必須 |
| `iteration` | number | 繰り返し回数（1から開始） | 必須 |
| `method` | string | 抽出方法（`generable`または`json`） | 必須 |
| `language` | string | 言語（`ja`または`en`） | 必須 |
| `experiment_pattern` | string | 実験パターン（`abs_gen`, `strict_json`, `persona-ex_json`など） | 必須 |
| `request_content` | string\|null | リクエスト内容（プロンプトやAIレスポンスなど） | オプション |
| `expected_fields` | array | 期待されるフィールドの配列 | 必須 |
| `unexpected_fields` | array | 期待されないフィールドの配列 | 必須 |
| `error` | string\|null | エラーメッセージ（エラーがない場合はnull） | オプション |

### 2ステップ抽出時の追加フィールド

| フィールド | 型 | 説明 | 必須 |
|-----------|-----|------|------|
| `two_steps_category` | object | 2ステップ抽出時のカテゴリ判定結果 | 2ステップ抽出時のみ |
| `two_steps_category.main_category` | string | メインカテゴリID（work, financial, digital, personal, infrastructure） | 2ステップ抽出時のみ |
| `two_steps_category.main_category_display` | string | メインカテゴリ表示名（日本語） | 2ステップ抽出時のみ |
| `two_steps_category.sub_category` | string | サブカテゴリID（workServer, financialCreditCardなど） | 2ステップ抽出時のみ |
| `two_steps_category.sub_category_display` | string | サブカテゴリ表示名（日本語） | 2ステップ抽出時のみ |

### エラー時の追加フィールド

| フィールド | 型 | 説明 | 必須 |
|-----------|-----|------|------|
| `error_type` | string | エラーの型（例: "ExtractionError"） | エラー時のみ |
| `ai_response` | string\|null | AIレスポンス（エラー時にAIレスポンスがある場合のみ） | オプション |

## フィールド定義

### 期待されるフィールド（パターン・レベル別）

#### Chat Level 1
- title, userID, password, note

#### Chat Level 2
- title, userID, password, url, note, host, port

#### Chat Level 3
- title, userID, password, url, note, host, port, authKey

#### Contract Level 1
- title, userID, password, note

#### Contract Level 2
- title, userID, password, url, note

#### Contract Level 3
- title, userID, password, url, note, host, port

#### CreditCard Level 1
- title, userID, password, note

#### CreditCard Level 2
- title, userID, password, note

#### CreditCard Level 3
- title, userID, password, note, authKey

#### VoiceRecognition Level 1
- title, userID, password, note

#### VoiceRecognition Level 2
- title, userID, password, note, host, port

#### VoiceRecognition Level 3
- title, userID, password, note, host, port, authKey

#### PasswordManager Level 1
- title, userID, password, note

#### PasswordManager Level 2
- title, userID, password, note, url

#### PasswordManager Level 3
- title, userID, password, note, url, host, port

## AI検証対象

### pending項目（AI検証が必要）
- **title**: 自由形式の記述が可能
- **note**: 自由形式の記述が可能

### 完全一致項目（プログラム判定）
- **userID**: 特定の値で完全一致が必要
- **password**: 特定の値で完全一致が必要
- **url**: 特定の値で完全一致が必要
- **host**: 特定の値で完全一致が必要
- **port**: 特定の値で完全一致が必要
- **authKey**: 特定の値で完全一致が必要

## 検証結果の更新形式

### 更新後のJSONファイル
AIは**必ず対応するテストデータと実際に抽出された値を比較して、**
pending項目のstatusを以下のように更新：
- `pending` → `correct` または `wrong`

## 例

### 正常時のログ（単純推定）
```json
{
  "pattern": "Chat",
  "level": 1,
  "iteration": 1,
  "method": "json",
  "language": "ja",
  "experiment_pattern": "strict_json",
  "request_content": "プロンプト内容...",
  "expected_fields": [
    {
      "name": "title",
      "value": "AWS EC2",
      "status": "pending"
    },
    {
      "name": "userID",
      "value": "admin",
      "status": "correct"
    },
    {
      "name": "password",
      "value": "SecurePass18329",
      "status": "correct"
    },
    {
      "name": "note",
      "value": "AWS EC2にログインするためのアカウント情報。",
      "status": "pending"
    }
  ],
  "unexpected_fields": [
    {
      "name": "url",
      "value": "https://ec2.amazonaws.com",
      "status": "unexpected"
    },
    {
      "name": "host",
      "value": "169.254.169.254",
      "status": "unexpected"
    },
    {
      "name": "port",
      "value": "22",
      "status": "unexpected"
    }
  ],
  "error": null
}
```

### 正常時のログ（2ステップ抽出）
```json
{
  "pattern": "Chat",
  "level": 1,
  "iteration": 1,
  "method": "json",
  "language": "ja",
  "experiment_pattern": "strict_json",
  "request_content": "```json\n{\n  \"serviceName\": \"AWS EC2\",\n  ...\n}\n```",
  "two_steps_category": {
    "main_category": "work",
    "main_category_display": "仕事・ビジネス",
    "sub_category": "workServer",
    "sub_category_display": "サーバー・VPS"
  },
  "expected_fields": [
    {
      "name": "title",
      "value": "AWS EC2",
      "status": "pending"
    },
    {
      "name": "userID",
      "value": "admin",
      "status": "correct"
    },
    {
      "name": "password",
      "value": "SecurePass18329",
      "status": "correct"
    },
    {
      "name": "note",
      "value": "AWS EC2にログインするためのアカウント情報。",
      "status": "pending"
    }
  ],
  "unexpected_fields": [
    {
      "name": "url",
      "value": "https://ec2.amazonaws.com",
      "status": "unexpected"
    }
  ],
  "error": null
}
```

### エラー時のログ
```json
{
  "pattern": "Chat",
  "level": 3,
  "iteration": 1,
  "method": "json",
  "language": "ja",
  "experiment_pattern": "strict_json",
  "request_content": null,
  "error": "無効な入力データです",
  "error_type": "ExtractionError",
  "ai_response": null,
  "expected_fields": [
    {
      "name": "title",
      "value": null,
      "status": "missing"
    },
    {
      "name": "userID",
      "value": null,
      "status": "missing"
    },
    {
      "name": "password",
      "value": null,
      "status": "missing"
    },
    {
      "name": "url",
      "value": null,
      "status": "missing"
    },
    {
      "name": "note",
      "value": null,
      "status": "missing"
    },
    {
      "name": "host",
      "value": null,
      "status": "missing"
    },
    {
      "name": "port",
      "value": null,
      "status": "missing"
    },
    {
      "name": "authKey",
      "value": null,
      "status": "missing"
    }
  ],
  "unexpected_fields": []
}
```

### AI検証後のログ（pending項目が更新された後）
```json
{
  "pattern": "Chat",
  "level": 1,
  "iteration": 1,
  "method": "json",
  "language": "ja",
  "experiment_pattern": "strict_json",
  "request_content": "プロンプト内容...",
  "expected_fields": [
    {
      "name": "title",
      "value": "AWS EC2",
      "status": "correct"
    },
    {
      "name": "userID",
      "value": "admin",
      "status": "correct"
    },
    {
      "name": "password",
      "value": "SecurePass18329",
      "status": "correct"
    },
    {
      "name": "note",
      "value": "AWS EC2にログインするためのアカウント情報。",
      "status": "correct"
    }
  ],
  "unexpected_fields": [],
  "error": null
}
```

## 注意事項

### ファイル名に関する注意事項

1. **ファイル名の一意性**: 同じテスト実行内でファイル名が重複しないようにする（`runNumber`を使用）
2. **エラー時のファイル名**: エラー時は`_error.json`サフィックスが付く場合がある（実装依存）

### JSON形式に関する注意事項

1. **JSONの妥当性**: 出力されるJSONは常に有効な形式である必要がある
2. **エンコーディング**: UTF-8でエンコードする
3. **null値の扱い**: 
   - 未抽出の場合は`null`を使用
   - 空文字列の場合は`""`を使用
   - `request_content`が未設定の場合は`null`を使用
4. **ステータスの一貫性**: 同じフィールドに対して複数のステータスが混在しないようにする

### フィールドに関する注意事項

1. **patternフィールド**: 大文字始まり（Chat, Contract, CreditCard, VoiceRecognition, PasswordManager）
2. **methodフィールド**: `generable`または`json`のみ（YAMLサポートは削除）
3. **experiment_patternフィールド**: 実験パターン名（`abs_gen`, `strict_json`, `persona-ex_json`など）
4. **two_steps_categoryフィールド**: 2ステップ抽出時のみ存在（単純推定時は存在しない）
5. **request_contentフィールド**: プロンプトやAIレスポンスを含む場合がある（nullの場合は未設定）

### エラーハンドリングに関する注意事項

1. **エラー時のexpected_fields**: すべての期待フィールドが`missing`ステータスで記録される
2. **エラー時のunexpected_fields**: エラー時は空配列`[]`になる
3. **error_typeフィールド**: エラー時のみ存在し、エラーの型を示す
4. **ai_responseフィールド**: エラー時にAIレスポンスがある場合のみ存在

## 更新履歴

- 2025-12-03: **v2.0 大幅更新**
  - ファイル名形式を実装に合わせて更新（`{testcase}_{algo}_{method}_{language}_level{level}_run{runNumber}.json`）
  - `experiment_pattern`フィールドを追加
  - `request_content`フィールドを追加
  - `two_steps_category`フィールドを追加（2ステップ抽出時のみ）
  - エラー時の`error_type`と`ai_response`フィールドを追加
  - YAMLサポート削除を反映（methodからyamlを削除）
  - patternフィールドの値が大文字始まりであることを明記
  - 例を実装に合わせて更新
