#!/usr/bin/env python3
"""
@ai[2025-01-18 06:40] 実験ログ監視スクリプト
目的: 並列実行中の実験のログファイルを監視し、完了を確認する
背景: 複数のアルゴリズムが並列実行されるため、個別の完了状況を追跡する必要がある
意図: ログファイルの生成状況を監視し、全アルゴリズムの完了を検知する
"""

import os
import time
import json
import argparse
from pathlib import Path
from typing import Dict, List, Set
from datetime import datetime

class ExperimentLogMonitor:
    def __init__(self, experiment_dir: str, algorithms: List[str], runs_per_algorithm: int = 20):
        self.experiment_dir = Path(experiment_dir)
        self.algorithms = algorithms
        self.runs_per_algorithm = runs_per_algorithm
        self.expected_logs_per_algorithm = runs_per_algorithm * 3  # 3 levels per run
        
    def monitor_experiments(self, check_interval: int = 10, max_wait_time: int = 3600):
        """実験の完了を監視"""
        print(f"🔍 実験ログ監視を開始します")
        print(f"   実験ディレクトリ: {self.experiment_dir}")
        print(f"   アルゴリズム: {', '.join(self.algorithms)}")
        print(f"   アルゴリズムあたりの実行回数: {self.runs_per_algorithm}")
        print(f"   期待ログ数/アルゴリズム: {self.expected_logs_per_algorithm}")
        print("=" * 80)
        
        start_time = time.time()
        completed_algorithms = set()
        
        while len(completed_algorithms) < len(self.algorithms):
            current_time = time.time()
            elapsed_time = current_time - start_time
            
            # 最大待機時間をチェック
            if elapsed_time > max_wait_time:
                print(f"⏰ 最大待機時間 ({max_wait_time}秒) に達しました")
                break
                
            # 各アルゴリズムの完了状況をチェック
            for algo in self.algorithms:
                if algo in completed_algorithms:
                    continue
                    
                log_count = self._count_algorithm_logs(algo)
                completion_rate = log_count / self.expected_logs_per_algorithm * 100
                
                if log_count >= self.expected_logs_per_algorithm:
                    if algo not in completed_algorithms:
                        print(f"✅ {algo} 完了 ({log_count}/{self.expected_logs_per_algorithm} ログ)")
                        completed_algorithms.add(algo)
                else:
                    print(f"🔄 {algo} 進行中 ({log_count}/{self.expected_logs_per_algorithm} ログ, {completion_rate:.1f}%)")
            
            # 全体の進捗を表示
            total_completed = len(completed_algorithms)
            total_algorithms = len(self.algorithms)
            overall_progress = total_completed / total_algorithms * 100
            
            print(f"📊 全体進捗: {total_completed}/{total_algorithms} アルゴリズム完了 ({overall_progress:.1f}%)")
            print(f"⏱️  経過時間: {elapsed_time:.0f}秒")
            
            if len(completed_algorithms) < len(self.algorithms):
                print(f"⏳ {check_interval}秒後に再チェック...")
                time.sleep(check_interval)
                print()  # 空行を追加
                
        # 最終結果を表示
        self._print_final_status(completed_algorithms, elapsed_time)
        
        return len(completed_algorithms) == len(self.algorithms)
        
    def _count_algorithm_logs(self, algorithm: str) -> int:
        """特定のアルゴリズムのログファイル数をカウント"""
        pattern = f"chat_{algorithm}_json_ja_level*_run*.json"
        log_files = list(self.experiment_dir.glob(pattern))
        return len(log_files)
        
    def _print_final_status(self, completed_algorithms: Set[str], elapsed_time: float):
        """最終的な完了状況を表示"""
        print("\n" + "=" * 80)
        print("📋 最終完了状況")
        print("=" * 80)
        
        for algo in self.algorithms:
            log_count = self._count_algorithm_logs(algo)
            status = "✅ 完了" if algo in completed_algorithms else "❌ 未完了"
            print(f"  {algo}: {log_count}/{self.expected_logs_per_algorithm} ログ - {status}")
            
        print(f"\n⏱️  総実行時間: {elapsed_time:.0f}秒 ({elapsed_time/60:.1f}分)")
        
        if len(completed_algorithms) == len(self.algorithms):
            print("🎉 全アルゴリズムが完了しました！")
        else:
            incomplete = set(self.algorithms) - completed_algorithms
            print(f"⚠️  未完了のアルゴリズム: {', '.join(incomplete)}")
            
    def get_algorithm_status(self) -> Dict[str, Dict]:
        """各アルゴリズムの詳細状況を取得"""
        status = {}
        
        for algo in self.algorithms:
            log_count = self._count_algorithm_logs(algo)
            completion_rate = log_count / self.expected_logs_per_algorithm * 100
            is_complete = log_count >= self.expected_logs_per_algorithm
            
            status[algo] = {
                'log_count': log_count,
                'expected_logs': self.expected_logs_per_algorithm,
                'completion_rate': completion_rate,
                'is_complete': is_complete
            }
            
        return status

def main():
    parser = argparse.ArgumentParser(description="実験ログ監視スクリプト")
    parser.add_argument("--experiment-dir", required=True, help="実験ディレクトリ")
    parser.add_argument("--algorithms", nargs="+", 
                       default=["abs", "abs-ex", "strict", "strict-ex", "persona", "persona-ex", "twosteps"],
                       help="監視するアルゴリズム")
    parser.add_argument("--runs-per-algorithm", type=int, default=20, help="アルゴリズムあたりの実行回数")
    parser.add_argument("--check-interval", type=int, default=10, help="チェック間隔（秒）")
    parser.add_argument("--max-wait-time", type=int, default=3600, help="最大待機時間（秒）")
    
    args = parser.parse_args()
    
    # 実験ディレクトリの存在確認
    if not os.path.exists(args.experiment_dir):
        print(f"❌ 実験ディレクトリが存在しません: {args.experiment_dir}")
        return 1
        
    # ログ監視を開始
    monitor = ExperimentLogMonitor(
        experiment_dir=args.experiment_dir,
        algorithms=args.algorithms,
        runs_per_algorithm=args.runs_per_algorithm
    )
    
    success = monitor.monitor_experiments(
        check_interval=args.check_interval,
        max_wait_time=args.max_wait_time
    )
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())
