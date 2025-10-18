#!/usr/bin/env python3
"""
@ai[2025-01-18 05:45] 実験進捗監視スクリプト
目的: 実行中の実験の進捗を監視し、完了時に通知する
背景: 長時間の実験の進捗を効率的に確認する必要がある
意図: 実験の完了を待機し、結果を自動的に表示する
"""

import os
import time
import glob
import subprocess
from datetime import datetime

def monitor_experiment(experiment_dir, patterns, runs_per_pattern):
    """実験の進捗を監視"""
    print(f"🔍 実験進捗を監視中: {experiment_dir}")
    print(f"   パターン数: {len(patterns)}")
    print(f"   パターンあたりの実行回数: {runs_per_pattern}")
    print("=" * 60)
    
    total_expected_files = len(patterns) * runs_per_pattern * 3  # 3 levels per run
    last_file_count = 0
    no_progress_count = 0
    
    while True:
        # ログファイル数をカウント
        log_files = glob.glob(f"{experiment_dir}/*.json")
        current_file_count = len(log_files)
        
        # 進捗を計算
        progress_percentage = (current_file_count / total_expected_files) * 100 if total_expected_files > 0 else 0
        
        # 進捗を表示
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] 進捗: {current_file_count}/{total_expected_files} ({progress_percentage:.1f}%)")
        
        # パターン別の進捗を表示
        for pattern in patterns:
            pattern_files = [f for f in log_files if pattern in f and not f.endswith('_error.json')]
            pattern_runs = set()
            for file in pattern_files:
                filename = os.path.basename(file)
                parts = filename.replace('.json', '').split('_')
                if len(parts) >= 6:
                    run_num = int(parts[5].replace('run', ''))
                    pattern_runs.add(run_num)
            
            completed_runs = len(pattern_runs)
            print(f"    {pattern}: {completed_runs}/{runs_per_pattern} 実行完了")
        
        # 完了チェック
        if current_file_count >= total_expected_files:
            print(f"\n✅ 実験完了！")
            print(f"   最終ファイル数: {current_file_count}")
            break
        
        # 進捗がない場合のカウンター
        if current_file_count == last_file_count:
            no_progress_count += 1
            if no_progress_count >= 10:  # 10回連続で進捗なし
                print(f"\n⚠️ 進捗が停止しています（{no_progress_count}回連続）")
                print(f"   現在のファイル数: {current_file_count}")
                print(f"   期待ファイル数: {total_expected_files}")
                break
        else:
            no_progress_count = 0
        
        last_file_count = current_file_count
        time.sleep(30)  # 30秒間隔でチェック
    
    return current_file_count >= total_expected_files

def generate_final_report(experiment_dir):
    """最終レポートを生成"""
    print(f"\n📊 最終レポートを生成中...")
    
    try:
        cmd = [
            "python3", "scripts/generate_combined_report.py",
            experiment_dir
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✅ レポート生成完了: {experiment_dir}/parallel_format_experiment_report.html")
            return True
        else:
            print(f"❌ レポート生成失敗: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ レポート生成エラー: {e}")
        return False

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="実験進捗監視スクリプト")
    parser.add_argument("--experiment-dir", required=True, help="実験ディレクトリ")
    parser.add_argument("--patterns", nargs="+", default=["chat_abs_json", "chat_abs-ex_json", "chat_strict_json", "chat_strict-ex_json", "chat_persona_json", "chat_persona-ex_json", "chat_twosteps_json_new"], help="監視するパターン")
    parser.add_argument("--runs-per-pattern", type=int, default=20, help="パターンあたりの実行回数")
    parser.add_argument("--generate-report", action="store_true", help="完了時にレポートを生成")
    
    args = parser.parse_args()
    
    # 実験を監視
    completed = monitor_experiment(args.experiment_dir, args.patterns, args.runs_per_pattern)
    
    # レポート生成
    if completed and args.generate_report:
        generate_final_report(args.experiment_dir)

if __name__ == "__main__":
    main()
