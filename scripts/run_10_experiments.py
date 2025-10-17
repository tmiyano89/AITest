#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
@ai[2025-01-10 15:45] 10回実験実行スクリプト（後方互換性維持版）
目的: Chatパターンのテストを10回実行して統計処理
背景: 1回の実行ではノイズが大きいため、複数回実行で安定した結果を取得
意図: 各パターンの真の性能を統計的に評価する
"""

import subprocess
import sys
from pathlib import Path

def main():
    """メイン処理 - 新しい拡張可能なスクリプトを呼び出し"""
    print("🚀 Chatパターン 10回実験を開始します...")
    print("使用パターン: chat_abs_gen (最良パターン)")
    print("🔄 新しい拡張可能なスクリプトを使用します...")
    print()
    
    # 新しい拡張可能なスクリプトを呼び出し
    cmd = [
        "python3", "scripts/run_experiments.py",
        "--patterns", "chat_abs_gen",
        "--runs", "10",
        "--language", "ja"
    ]
    
    try:
        result = subprocess.run(cmd, check=True)
        print("\n✅ 実験完了")
    except subprocess.CalledProcessError as e:
        print(f"❌ 実験実行エラー: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print("❌ 新しい実験スクリプトが見つかりません: scripts/run_experiments.py")
        sys.exit(1)

if __name__ == "__main__":
    main()