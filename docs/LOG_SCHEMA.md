# AITestApp ログスキーマ定義

## 概要
AITestAppが出力する構造化JSONログのスキーマ定義です。このスキーマに基づいてログの解析とAI検証を行います。

## ログファイル形式

### ファイル名
```
{method}_{language}_{pattern}_level{level}_{iteration}.json
```

例：
- `generable_ja_chat_level1_1.json`
- `json_en_creditcard_level2_3.json`
- `yaml_ja_contract_level3_2_error.json`

### JSONスキーマ

#### 基本構造
```json
{
  "pattern": "string",           // テストパターン (chat, contract, creditcard, voicerecognition, passwordmanager)
  "level": number,               // レベル (1, 2, 3)
  "iteration": number,           // 繰り返し回数 (1, 2, 3)
  "method": "string",            // 抽出方法 (generable, json, yaml)
  "language": "string",          // 言語 (ja, en)
  "expected_fields": [           // 期待されるフィールドの配列(抽出すべき項目をすべて記載すること)
    {
      "name": "string",          // フィールド名 (title, userID, password, url, note, host, port, authKey)
      "value": "string|null",    // 抽出された値 (nullの場合は未抽出)
      "status": "string"         // ステータス (correct, wrong, missing, unexpected, pending)
    }
  ],
  "unexpected_fields": [         // 期待されないフィールドの配列(実際に抽出された項目のみ記載すること)
    {
      "name": "string",          // フィールド名
      "value": "string",         // 抽出された値
      "status": "unexpected"     // 常に"unexpected"
    }
  ],
  "error": "string|null"         // エラーメッセージ (エラーがない場合はnull)
}
```

## ステータス定義

### expected_fieldsのstatus
- **correct**: 正しく抽出された
- **wrong**: 抽出されたが値が間違っている
- **missing**: 抽出されなかった
- **unexpected**: 期待されない項目だが抽出された（通常はexpected_fieldsには含まれない）
- **pending**: AIによる検証が必要（title、noteのみ）

### unexpected_fieldsのstatus
- **unexpected**: 期待されない項目が抽出された

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

### 入力ログ（更新前）
```json
{
  "pattern": "chat",
  "level": 1,
  "iteration": 1,
  "method": "generable",
  "language": "ja",
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
      "value": "新しいサーバーのアカウント情報",
      "status": "pending"
    }
  ],
  "unexpected_fields": [],
  "error": null
}
```

### 更新後ログ
```json
{
  "pattern": "chat",
  "level": 1,
  "iteration": 1,
  "method": "generable",
  "language": "ja",
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
      "value": "新しいサーバーのアカウント情報",
      "status": "correct"
    }
  ],
  "unexpected_fields": [],
  "error": null
}
```

## 注意事項

1. **ファイル名の一意性**: 同じテスト実行内でファイル名が重複しないようにする
2. **JSONの妥当性**: 出力されるJSONは常に有効な形式である必要がある
3. **エンコーディング**: UTF-8でエンコードする
4. **null値の扱い**: 未抽出の場合は`null`、空文字列の場合は`""`を使用する
5. **ステータスの一貫性**: 同じフィールドに対して複数のステータスが混在しないようにする
