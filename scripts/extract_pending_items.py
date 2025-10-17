#!/usr/bin/env python3
"""
pending項目抽出スクリプト
指定したテストケースと項目名のpending状態データをCSV形式で抽出する
"""

import json
import csv
import sys
from pathlib import Path
import argparse

def extract_pending_items(test_case_pattern, field_name, log_dir, all_items=False):
    """
    指定したテストケースと項目名のデータを抽出
    
    Args:
        test_case_pattern: テストケースパターン（例: "chat_ja_level1"）
        field_name: 項目名（例: "title", "note"）
        log_dir: ログディレクトリパス
        all_items: Trueの場合はstatusに関係なくすべての項目を抽出、Falseの場合はpendingのみ
    """
    
    log_path = Path(log_dir)
    if not log_path.exists():
        print(f"エラー: ログディレクトリが見つかりません: {log_dir}")
        return
    
    # パターンに一致するJSONファイルを検索
    json_files = list(log_path.glob(f"*{test_case_pattern}*.json"))
    
    if not json_files:
        print(f"エラー: パターン '{test_case_pattern}' に一致するファイルが見つかりません")
        return
    
    pending_items = []
    
    for json_file in json_files:
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # expected_fieldsから指定された項目を検索
            if 'expected_fields' in data:
                for field in data['expected_fields']:
                    if field.get('name') == field_name:
                        # all_itemsがTrueの場合はstatusに関係なく抽出
                        # all_itemsがFalseの場合はpendingのみ抽出
                        if all_items or field.get('status') == 'pending':
                            
                            # 値の正規化（null, "nil", 空文字列の場合はmissingとして扱う）
                            value = field.get('value', '')
                            if value is None or value == 'nil' or value == '':
                                status = 'missing'
                            else:
                                status = field.get('status', 'pending')
                            
                            pending_items.append({
                                'file_name': json_file.name,
                                'value': value,
                                'status': status
                            })
        
        except Exception as e:
            print(f"警告: ファイル {json_file.name} の読み込みに失敗: {e}")
            continue
    
    if not pending_items:
        status_text = "すべての" if all_items else "pending状態の"
        print(f"パターン '{test_case_pattern}' の項目 '{field_name}' に{status_text}データが見つかりません")
        return
    
    # CSV形式で出力
    status_text = "すべての" if all_items else "pending"
    print(f"=== {test_case_pattern} - {field_name} {status_text}項目一覧 ===")
    print("ファイル名,値,status")
    
    for item in pending_items:
        # CSV形式で出力（値にカンマが含まれる場合は適切にエスケープ）
        value = str(item['value']).replace('"', '""')  # ダブルクォートをエスケープ
        if ',' in value or '"' in value or '\n' in value:
            value = f'"{value}"'  # 値をダブルクォートで囲む
        
        print(f"{item['file_name']},{value},{item['status']}")
    
    status_text = "すべての" if all_items else "pending"
    print(f"\n合計: {len(pending_items)}件の{status_text}項目が見つかりました")
    
    # 作業完了後の自動削除メッセージ
    print(f"\n⚠️  注意: この出力をCSVファイルに保存して検証後、中間ファイルは自動削除されます")

def main():
    parser = argparse.ArgumentParser(description='pending項目抽出スクリプト')
    parser.add_argument('test_case', help='テストケースパターン（例: chat_ja_level1）')
    parser.add_argument('field_name', help='項目名（例: title, note）')
    parser.add_argument('--log-dir', default='test_logs/202510171800_multi_experiments', 
                       help='ログディレクトリ（デフォルト: test_logs/202510171800_multi_experiments）')
    parser.add_argument('--all-items', action='store_true',
                       help='statusに関係なくすべての項目を抽出（デフォルト: pendingのみ）')
    
    args = parser.parse_args()
    
    extract_pending_items(args.test_case, args.field_name, args.log_dir, args.all_items)

if __name__ == "__main__":
    main()
