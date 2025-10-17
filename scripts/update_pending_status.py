#!/usr/bin/env python3
"""
項目ステータス更新スクリプト（コンパクト形式対応）
CSVファイルの検証結果を元に、JSONログファイルの指定項目のステータスを更新する
correct以外のケースのみ記載するコンパクト形式に対応
"""

import json
import csv
import sys
from pathlib import Path
import argparse

def update_pending_status(csv_file, log_dir, field_name):
    """
    CSVファイルの検証結果を元に、JSONログファイルの指定項目のステータスを更新
    
    Args:
        csv_file: 検証結果CSVファイルのパス（correct以外のケースのみ記載）
        log_dir: ログディレクトリパス
        field_name: 更新対象の項目名（例: "title", "note"）
    """
    
    csv_path = Path(csv_file)
    if not csv_path.exists():
        print(f"エラー: CSVファイルが見つかりません: {csv_file}")
        return
    
    log_path = Path(log_dir)
    if not log_path.exists():
        print(f"エラー: ログディレクトリが見つかりません: {log_dir}")
        return
    
    # CSVファイルを読み込み（correct以外のケースのみ）
    updates = {}
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                file_name = row['ファイル名']
                status = row['判定']
                reason = row.get('理由', '')
                
                # correct以外のケースのみ記録
                if status != 'correct':
                    updates[file_name] = {
                        'status': status,
                        'reason': reason
                    }
    except Exception as e:
        print(f"エラー: CSVファイルの読み込みに失敗: {e}")
        return
    
    print(f"更新対象項目: {field_name}")
    print(f"CSVファイル記載件数: {len(updates)}件")
    
    # ログディレクトリ内のすべてのJSONファイルを検索
    json_files = list(log_path.glob("*.json"))
    if not json_files:
        print(f"エラー: JSONファイルが見つかりません")
        return
    
    print(f"対象JSONファイル数: {len(json_files)}件")
    
    # 各JSONファイルを更新
    updated_count = 0
    correct_count = 0
    error_count = 0
    
    for json_file in json_files:
        try:
            # JSONファイルを読み込み
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # expected_fieldsから該当項目を検索して更新
            updated = False
            if 'expected_fields' in data:
                for field in data['expected_fields']:
                    if field.get('name') == field_name:
                        file_name = json_file.name
                        
                        if file_name in updates:
                            # CSVファイルに記載がある場合（correct以外）
                            old_status = field.get('status')
                            new_status = updates[file_name]['status']
                            field['status'] = new_status
                            updated = True
                            updated_count += 1
                            
                            print(f"更新: {file_name} - {field_name} ({old_status} → {new_status})")
                        else:
                            # CSVファイルに記載がない場合（correct）
                            old_status = field.get('status')
                            if old_status != 'correct':
                                field['status'] = 'correct'
                                updated = True
                                correct_count += 1
                                print(f"修正: {file_name} - {field_name} ({old_status} → correct)")
                            else:
                                updated = True  # 維持の場合もupdated=Trueに設定
                                print(f"維持: {file_name} - {field_name} (correct)")
                        break
            
            if not updated:
                print(f"警告: 該当項目が見つかりません: {json_file.name} - {field_name}")
                error_count += 1
                continue
            
            # JSONファイルを保存
            with open(json_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            
        except Exception as e:
            print(f"エラー: ファイル {json_file.name} の更新に失敗: {e}")
            error_count += 1
            continue
    
    print(f"\n--- 更新処理完了 ---")
    print(f"CSV記載分の更新: {updated_count}件")
    print(f"correct修正: {correct_count}件")
    print(f"エラー: {error_count}件")
    print(f"合計処理: {updated_count + correct_count}件")
    
    # 作業完了後の自動削除メッセージ
    print(f"\n⚠️  注意: 作業完了後、中間CSVファイルは自動削除されます")

def main():
    parser = argparse.ArgumentParser(description='項目ステータス更新スクリプト（コンパクト形式対応）')
    parser.add_argument('csv_file', help='検証結果CSVファイルのパス（correct以外のケースのみ記載）')
    parser.add_argument('log_dir', help='ログディレクトリパス')
    parser.add_argument('field_name', help='更新対象の項目名（例: title, note）')
    
    args = parser.parse_args()
    
    update_pending_status(args.csv_file, args.log_dir, args.field_name)

if __name__ == "__main__":
    main()