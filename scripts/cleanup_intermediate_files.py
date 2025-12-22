#!/usr/bin/env python3
"""
中間ファイル自動削除スクリプト
pending項目検証作業で作成された中間ファイルを自動削除します
tmp/{test-id}ディレクトリごと削除します
"""

import os
import shutil
import sys
from pathlib import Path
import argparse

def cleanup_intermediate_files(test_id=None):
    """
    pending項目検証作業で作成された中間ファイルを削除
    
    Args:
        test_id: テストID（例: 202511270642_json_ja_two-steps_a3f2）
                指定された場合、tmp/{test_id}ディレクトリごと削除
                指定されない場合、tmp/ディレクトリ内のすべてのディレクトリを削除
    """
    tmp_dir = Path("tmp")
    
    if not tmp_dir.exists():
        print("✅ tmpディレクトリが存在しないため、削除対象はありません")
        return
    
    if test_id:
        # 指定されたtest-idのディレクトリを削除
        target_dir = tmp_dir / test_id
        if target_dir.exists():
            try:
                shutil.rmtree(target_dir)
                print(f"✅ 削除: {target_dir}")
            except OSError as e:
                print(f"❌ 削除エラー: {target_dir} - {e}")
                return
        else:
            print(f"⚠️  ディレクトリが見つかりません: {target_dir}")
            return
    else:
        # tmpディレクトリ内のすべてのディレクトリを削除
        deleted_dirs = []
        for item in tmp_dir.iterdir():
            if item.is_dir():
                try:
                    shutil.rmtree(item)
                    deleted_dirs.append(item)
                    print(f"削除: {item}")
                except OSError as e:
                    print(f"削除エラー: {item} - {e}")
        
        if deleted_dirs:
            print(f"\n✅ 中間ファイル削除完了: {len(deleted_dirs)}ディレクトリ")
        else:
            print("\n✅ 削除対象の中間ファイルディレクトリはありませんでした")

def main():
    parser = argparse.ArgumentParser(description='中間ファイル自動削除スクリプト')
    parser.add_argument('--test-id', help='テストID（例: 202511270642_json_ja_two-steps_a3f2）。指定された場合、tmp/{test-id}ディレクトリのみ削除。指定されない場合、tmp/ディレクトリ内のすべてのディレクトリを削除。')
    
    args = parser.parse_args()
    
    cleanup_intermediate_files(args.test_id)

if __name__ == "__main__":
    main()
