#!/usr/bin/env python3
import json
import re

# AIレスポンスをテスト
ai_response = """```json
{
  "type": "SSH接続",
  "title": "AWS EC2 instance",
  "userID": "root",
  "host": "ec2-54-123-45-67.compute-1.amazonaws.com(197.78.64.33)",
  "port": 22,
  "note": "Password: SuperSecure2024#, AWS console URL: https://console.aws.amazon.com/ec2/, Private key present"
}
```"""

print('=== AIレスポンス解析 ===')
print('元のレスポンス:')
print(repr(ai_response))
print()

# パターン1: ```json ... ``` で囲まれたJSONを抽出
pattern1 = r'```json\s*([\s\S]*?)\s*```'
match1 = re.search(pattern1, ai_response)
if match1:
    json1 = match1.group(1).strip()
    print('✅ パターン1で抽出されたJSON:')
    print(repr(json1))
    print()
    
    # JSONの有効性をテスト
    try:
        data = json.loads(json1)
        print('✅ パターン1のJSONは有効です')
        print(f'   抽出されたフィールド: {list(data.keys())}')
        print(f'   データ: {data}')
    except json.JSONDecodeError as e:
        print(f'❌ パターン1のJSONは無効です: {e}')
        print(f'   エラー位置: {e.pos}')
        print(f'   エラー前の文字: {repr(json1[max(0, e.pos-10):e.pos+10])}')
else:
    print('❌ パターン1: マッチしませんでした')

# パターン2: 最初の{から最後の}まで
start = ai_response.find('{')
end = ai_response.rfind('}')
if start != -1 and end != -1 and start < end:
    json2 = ai_response[start:end+1]
    print('\n✅ パターン2で抽出されたJSON:')
    print(repr(json2))
    print()
    
    try:
        data = json.loads(json2)
        print('✅ パターン2のJSONは有効です')
        print(f'   抽出されたフィールド: {list(data.keys())}')
    except json.JSONDecodeError as e:
        print(f'❌ パターン2のJSONは無効です: {e}')
        print(f'   エラー位置: {e.pos}')
        print(f'   エラー前の文字: {repr(json2[max(0, e.pos-10):e.pos+10])}')
else:
    print('\n❌ パターン2: マッチしませんでした')

# AccountInfoの期待フィールドと比較
expected_fields = ['title', 'userID', 'password', 'url', 'note', 'host', 'port', 'authKey']
print(f'\n=== フィールド比較 ===')
print(f'期待フィールド: {expected_fields}')

if match1:
    try:
        data = json.loads(match1.group(1).strip())
        actual_fields = list(data.keys())
        print(f'実際のフィールド: {actual_fields}')
        
        missing_fields = set(expected_fields) - set(actual_fields)
        extra_fields = set(actual_fields) - set(expected_fields)
        
        print(f'不足フィールド: {list(missing_fields)}')
        print(f'余分フィールド: {list(extra_fields)}')
        
    except json.JSONDecodeError:
        print('JSON解析失敗のため比較できません')
