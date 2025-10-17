#!/usr/bin/env python3
"""
中間ファイル自動削除スクリプト
pending項目検証作業で作成された中間ファイルを自動削除します
"""

import os
import glob
from pathlib import Path

def cleanup_intermediate_files():
    """
    pending項目検証作業で作成された中間ファイルを削除
    """
    # 削除対象のファイルパターン
    patterns = [
        "level*_verification*.csv",
        "level*_title_all.csv", 
        "level*_note_all.csv",
        "pending_verification_results.csv"
    ]
    
    deleted_files = []
    
    for pattern in patterns:
        files = glob.glob(pattern)
        for file_path in files:
            try:
                os.remove(file_path)
                deleted_files.append(file_path)
                print(f"削除: {file_path}")
            except OSError as e:
                print(f"削除エラー: {file_path} - {e}")
    
    if deleted_files:
        print(f"\n✅ 中間ファイル削除完了: {len(deleted_files)}件")
    else:
        print("\n✅ 削除対象の中間ファイルはありませんでした")

if __name__ == "__main__":
    cleanup_intermediate_files()
