#!/usr/bin/env python3
"""
@ai[2025-01-18 06:35] 並列実行管理スクリプト
目的: 複数のアルゴリズムを並列実行し、完了を監視して集計する
背景: シーケンシャル実行では時間がかかりすぎるため、並列実行で効率化
意図: algoごとにバックグラウンド実行し、全完了後に集計処理を実行
"""

import subprocess
import sys
import os
import time
import signal
import threading
from datetime import datetime
from pathlib import Path
import json
import argparse
from typing import Dict, List, Optional
from experiment_log_monitor import ExperimentLogMonitor

class ParallelExperimentManager:
    def __init__(self, external_llm_url: str, external_llm_model: str, 
                 algorithms: List[str], runs: int = 20, experiment_dir: Optional[str] = None):
        self.external_llm_url = external_llm_url
        self.external_llm_model = external_llm_model
        self.algorithms = algorithms
        self.runs = runs
        self.experiment_dir = experiment_dir or self._create_experiment_dir()
        self.running_processes: Dict[str, subprocess.Popen] = {}
        self.completed_algorithms: List[str] = []
        self.shutdown_requested = False
        
        # シグナルハンドラーを設定
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
    def _create_experiment_dir(self) -> str:
        """実験ディレクトリを作成"""
        timestamp = datetime.now().strftime("%Y%m%d%H%M")
        experiment_dir = f"test_logs/{timestamp}_parallel_external_llm_experiment"
        os.makedirs(experiment_dir, exist_ok=True)
        return experiment_dir
        
    def _signal_handler(self, signum, frame):
        """シグナルハンドラー（Ctrl+C等で実行中のプロセスを停止）"""
        print(f"\n🛑 シグナル {signum} を受信しました。実行中のプロセスを停止します...")
        self.shutdown_requested = True
        self._stop_all_processes()
        sys.exit(1)
        
    def _stop_all_processes(self):
        """実行中の全プロセスを停止"""
        for algo, process in self.running_processes.items():
            if process.poll() is None:  # プロセスが実行中の場合
                print(f"  🛑 {algo} のプロセスを停止中...")
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    print(f"  ⚠️ {algo} のプロセスを強制終了します")
                    process.kill()
                    
    def run_parallel_experiments(self):
        """並列実験を実行"""
        print("🚀 並列外部LLM実験を開始します")
        print(f"   外部LLM URL: {self.external_llm_url}")
        print(f"   外部LLM モデル: {self.external_llm_model}")
        print(f"   アルゴリズム: {', '.join(self.algorithms)}")
        print(f"   実行回数: {self.runs}")
        print(f"   実験ディレクトリ: {self.experiment_dir}")
        print("=" * 80)
        
        # 各アルゴリズムを並列実行
        for algo in self.algorithms:
            self._start_algorithm_experiment(algo)
            
        # ログ監視で完了を確認
        self._monitor_experiments_with_logs()
        
        # 全完了後に集計
        if not self.shutdown_requested:
            self._generate_final_report()
            
    def _start_algorithm_experiment(self, algo: str):
        """特定のアルゴリズムの実験をバックグラウンドで開始"""
        print(f"🔬 {algo} の実験を開始中...")
        
        # パターンリストを作成（各アルゴリズムで3つのレベルを実行）
        patterns = [f"chat_{algo}_json"]
        
        # 実験スクリプトを実行（集計なし）
        cmd = [
            "python3", "scripts/run_external_llm_experiment.py",
            "--external-llm-url", self.external_llm_url,
            "--external-llm-model", self.external_llm_model,
            "--patterns"] + patterns + [
            "--runs", str(self.runs),
            "--experiment-dir", self.experiment_dir
        ]
        
        try:
            # バックグラウンドで実行
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            self.running_processes[algo] = process
            print(f"  ✅ {algo} のプロセスを開始 (PID: {process.pid})")
            
        except Exception as e:
            print(f"  ❌ {algo} の開始に失敗: {e}")
            
    def _monitor_experiments_with_logs(self):
        """ログファイル監視で実験の完了を確認"""
        print(f"\n📊 ログファイル監視で実験完了を確認します...")
        
        # ログ監視スクリプトを使用
        monitor = ExperimentLogMonitor(
            experiment_dir=self.experiment_dir,
            algorithms=self.algorithms,
            runs_per_algorithm=self.runs
        )
        
        # 監視を実行
        success = monitor.monitor_experiments(
            check_interval=10,  # 10秒間隔でチェック
            max_wait_time=7200  # 最大2時間待機
        )
        
        if success:
            print(f"\n🎉 全実験が完了しました！")
        else:
            print(f"\n⚠️ 一部の実験が未完了の可能性があります")
            
    def _monitor_experiments(self):
        """実行中の実験を監視（プロセス監視版）"""
        print(f"\n📊 実験監視を開始します...")
        
        while self.running_processes and not self.shutdown_requested:
            completed_this_round = []
            
            for algo, process in list(self.running_processes.items()):
                # プロセスの状態をチェック
                return_code = process.poll()
                
                if return_code is not None:  # プロセスが終了した場合
                    if return_code == 0:
                        print(f"  ✅ {algo} 完了")
                        self.completed_algorithms.append(algo)
                    else:
                        print(f"  ❌ {algo} 失敗 (コード: {return_code})")
                        # エラー出力を表示
                        stderr = process.stderr.read()
                        if stderr:
                            print(f"     エラー: {stderr[:200]}...")
                    
                    completed_this_round.append(algo)
                    
            # 完了したプロセスを削除
            for algo in completed_this_round:
                del self.running_processes[algo]
                
            # 進捗表示
            total_algorithms = len(self.algorithms)
            completed_count = len(self.completed_algorithms)
            running_count = len(self.running_processes)
            
            print(f"  📈 進捗: {completed_count}/{total_algorithms} 完了, {running_count} 実行中")
            
            if self.running_processes:
                time.sleep(5)  # 5秒間隔でチェック
                
        if not self.shutdown_requested:
            print(f"\n🎉 全実験が完了しました！")
            print(f"   完了したアルゴリズム: {', '.join(self.completed_algorithms)}")
            
    def _generate_final_report(self):
        """最終レポートを生成"""
        print(f"\n📊 最終レポートを生成中...")
        
        try:
            # 集計スクリプトを実行
            cmd = [
                "python3", "scripts/generate_combined_report.py",
                self.experiment_dir
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ レポート生成完了: {self.experiment_dir}/parallel_format_experiment_report.html")
            else:
                print(f"❌ レポート生成失敗: {result.stderr}")
                
        except Exception as e:
            print(f"❌ レポート生成エラー: {e}")

def main():
    parser = argparse.ArgumentParser(description="並列外部LLM実験管理スクリプト（新しい引数方式）")
    parser.add_argument("--external-llm-url", help="外部LLMサーバーのURL（指定しない場合はFoundationModelsを使用）")
    parser.add_argument("--external-llm-model", help="外部LLMモデル名（指定しない場合はFoundationModelsを使用）")
    parser.add_argument("--method", default='generable', choices=['json', 'generable', 'yaml'],
                       help='抽出方法 (json/generable/yaml, デフォルト: generable)')
    parser.add_argument("--testcases", nargs='+', default=['chat'],
                       choices=['chat', 'creditcard', 'contract', 'password', 'voice'],
                       help='テストケース (chat/creditcard/contract/password/voice, デフォルト: chat)')
    parser.add_argument("--algos", nargs='+', 
                       default=['abs', 'strict', 'persona', 'twosteps', 'abs-ex', 'strict-ex', 'persona-ex'],
                       choices=['abs', 'strict', 'persona', 'twosteps', 'abs-ex', 'strict-ex', 'persona-ex'],
                       help='アルゴリズム (abs/strict/persona/twosteps/abs-ex/strict-ex/persona-ex, デフォルト: すべて)')
    parser.add_argument("--levels", nargs='+', type=int, default=[1, 2, 3],
                       choices=[1, 2, 3],
                       help='レベル (1/2/3, デフォルト: 1,2,3)')
    parser.add_argument("--language", default='ja', choices=['ja', 'en'],
                       help='言語 (ja/en, デフォルト: ja)')
    parser.add_argument("--runs", type=int, default=20, help="各アルゴリズムの実行回数")
    parser.add_argument("--experiment-dir", help="実験ディレクトリ（指定しない場合は自動作成）")
    
    args = parser.parse_args()
    
    # 並列実験実行
    manager = ParallelExperimentManager(
        external_llm_url=args.external_llm_url,
        external_llm_model=args.external_llm_model,
        algorithms=args.algos,  # 新しい引数名に変更
        runs=args.runs,
        experiment_dir=args.experiment_dir
    )
    
    manager.run_parallel_experiments()

if __name__ == "__main__":
    main()
