#!/usr/bin/env python3
import re

text = """**抽出されたアカウント情報**

```json
{
  "username": "root",
  "password": "SuperSecure2024#",
  "host": "ec2-54-123-45-67.compute-1.amazonaws.com",
  "port": "22",
  "private_key": "BEGIN OPENSSH PRIVATE KEY
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABFwAAAAdzc2gtcn
RhAAAAAwEAAQAAAQEA1234567890abcdef
END OPENSSH PRIVATE KEY",
  "console_url": "https://console.aws.amazon.com/ec2/"
}
```

> **備考**  
> * すべてのフィールドに値が存在し、`nil` は設定されていません。  
> * 必要に応じて、他の情報（例：RDS 接続情報等）は追加の抽出対象にしてください。"""

print("=== JSON抽出テスト ===")

# パターン1: ```json ... ``` で囲まれたJSON
pattern1 = r'```json\s*([\s\S]*?)\s*```'
match1 = re.search(pattern1, text)
if match1:
    json1 = match1.group(1).strip()
    print('✅ パターン1で抽出されたJSON:')
    print(json1)
    print('---')
else:
    print('❌ パターン1: マッチしませんでした')

# パターン2: 最初の{から最後の}まで
start = text.find('{')
end = text.rfind('}')
if start != -1 and end != -1 and start < end:
    json2 = text[start:end+1]
    print('✅ パターン2で抽出されたJSON:')
    print(json2)
    print('---')
else:
    print('❌ パターン2: マッチしませんでした')

# JSONの有効性をテスト
import json
try:
    if match1:
        data = json.loads(json1)
        print('✅ パターン1のJSONは有効です')
        print(f'   抽出されたフィールド: {list(data.keys())}')
    else:
        print('❌ パターン1のJSONは抽出できませんでした')
except json.JSONDecodeError as e:
    print(f'❌ パターン1のJSONは無効です: {e}')

try:
    if start != -1 and end != -1:
        data = json.loads(json2)
        print('✅ パターン2のJSONは有効です')
        print(f'   抽出されたフィールド: {list(data.keys())}')
    else:
        print('❌ パターン2のJSONは抽出できませんでした')
except json.JSONDecodeError as e:
    print(f'❌ パターン2のJSONは無効です: {e}')
