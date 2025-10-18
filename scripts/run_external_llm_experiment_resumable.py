#!/usr/bin/env python3
"""
@ai[2025-01-18 05:30] レジューム可能な外部LLM実験実行スクリプト
目的: 中断された外部LLM実験を途中から再開できるようにする
背景: 長時間の実験で中断が発生した場合の効率的な再開が必要
意図: 既存のログファイルを確認し、未完了のパターン・実行のみを実行
"""

import subprocess
import sys
import os
import time
from datetime import datetime
from pathlib import Path
import json
import argparse
import glob

class ResumableExternalLLMExperimentRunner:
    def __init__(self, external_llm_url: str, external_llm_model: str, patterns: list, runs: int = 20, experiment_dir: str = None):
        self.external_llm_url = external_llm_url
        self.external_llm_model = external_llm_model
        self.patterns = patterns
        self.runs = runs
        self.experiment_dir = experiment_dir or self._create_experiment_dir()
        
    def _create_experiment_dir(self):
        """実験ディレクトリを作成"""
        timestamp = datetime.now().strftime("%Y%m%d%H%M")
        return f"test_logs/{timestamp}_external_llm_experiment"
    
    def analyze_existing_logs(self):
        """既存のログファイルを分析して進捗を確認"""
        print("🔍 既存のログファイルを分析中...")
        
        # ログファイルのパターンを分析
        log_files = glob.glob(f"{self.experiment_dir}/*.json")
        print(f"   見つかったログファイル: {len(log_files)}個")
        
        # パターン別の完了状況を分析
        pattern_progress = {}
        for pattern in self.patterns:
            pattern_progress[pattern] = {
                'completed_runs': set(),
                'total_runs': self.runs,
                'levels': set()
            }
            
            # パターンに対応するログファイルを検索
            pattern_files = [f for f in log_files if pattern in f and not f.endswith('_error.json')]
            
            for log_file in pattern_files:
                # ファイル名から実行回数とレベルを抽出
                filename = os.path.basename(log_file)
                parts = filename.replace('.json', '').split('_')
                
                if len(parts) >= 6:
                    level = parts[4]  # level1, level2, level3
                    run_num = int(parts[5].replace('run', ''))
                    
                    pattern_progress[pattern]['completed_runs'].add(run_num)
                    pattern_progress[pattern]['levels'].add(level)
        
        return pattern_progress
    
    def run_experiment(self):
        """レジューム可能な外部LLM実験を実行"""
        print("🌐 レジューム可能な外部LLM実験を開始します")
        print(f"   外部LLM URL: {self.external_llm_url}")
        print(f"   外部LLM モデル: {self.external_llm_model}")
        print(f"   パターン: {', '.join(self.patterns)}")
        print(f"   実行回数: {self.runs}")
        print(f"   実験ディレクトリ: {self.experiment_dir}")
        print("=" * 80)
        
        # 実験ディレクトリを作成
        os.makedirs(self.experiment_dir, exist_ok=True)
        
        # 既存のログを分析
        progress = self.analyze_existing_logs()
        
        # 進捗を表示
        print("\n📊 現在の進捗:")
        for pattern in self.patterns:
            completed = len(progress[pattern]['completed_runs'])
            total = progress[pattern]['total_runs']
            percentage = (completed / total) * 100 if total > 0 else 0
            print(f"   {pattern}: {completed}/{total} ({percentage:.1f}%)")
        
        # 各パターンで実験を実行
        for i, pattern in enumerate(self.patterns):
            print(f"\n🔬 パターン {i+1}/{len(self.patterns)}: '{pattern}' の実験を開始")
            self.run_pattern_experiment(pattern, progress[pattern])
        
        print(f"\n✅ 外部LLM実験完了")
        print(f"📁 結果ディレクトリ: {self.experiment_dir}")
        
    def run_pattern_experiment(self, pattern: str, progress_info: dict):
        """特定のパターンで実験を実行（レジューム対応）"""
        print(f"  📋 パターン: {pattern}")
        
        # パターンから抽出方法と言語を解析
        parts = pattern.split('_')
        if len(parts) < 3:
            print(f"  ❌ 無効なパターン形式: {pattern}")
            return
            
        method = parts[1]  # abs, persona, etc.
        language = parts[2]  # ja, en
        
        # 外部LLM実験では日本語のみをサポート
        if language != "ja":
            print(f"  ⚠️ 外部LLM実験では日本語のみサポート: {language} -> ja")
            language = "ja"
        
        # 未完了の実行を特定
        completed_runs = progress_info['completed_runs']
        remaining_runs = [run_num for run_num in range(1, self.runs + 1) if run_num not in completed_runs]
        
        if not remaining_runs:
            print(f"    ✅ すべての実行が完了済み")
            return
            
        print(f"    🔄 未完了の実行: {len(remaining_runs)}/{self.runs} 件")
        
        # 未完了の実行を実行
        for run_num in remaining_runs:
            print(f"    🔄 実行 {run_num}/{self.runs} (進捗: {run_num/self.runs*100:.1f}%)")
            
            try:
                # Swiftアプリケーションを実行
                cmd = [
                    "swift", "run", "AITestApp",
                    "--experiment", f"json_{language}",
                    "--pattern", pattern,
                    "--test-dir", self.experiment_dir,
                    "--external-llm-url", self.external_llm_url,
                    "--external-llm-model", self.external_llm_model
                ]
                
                # 環境変数でrunNumberを設定
                env = os.environ.copy()
                env["AITEST_RUN_NUMBER"] = str(run_num)
                
                result = subprocess.run(
                    cmd,
                    env=env,
                    capture_output=True,
                    text=True,
                    timeout=600  # 10分タイムアウト
                )
                
                if result.returncode == 0:
                    print(f"      ✅ 成功")
                else:
                    print(f"      ❌ 失敗 (コード: {result.returncode})")
                    if result.stderr:
                        print(f"        エラー: {result.stderr[:200]}...")
                    if result.stdout:
                        print(f"        出力: {result.stdout[:200]}...")
                    
            except subprocess.TimeoutExpired:
                print(f"      ⏰ タイムアウト (10分)")
            except Exception as e:
                print(f"      ❌ エラー: {e}")
            
            # 進捗表示
            if run_num % 5 == 0:
                print(f"    📊 進捗: {run_num}/{self.runs} 完了")
    
    def generate_report(self):
        """実験結果のレポートを生成"""
        print(f"\n📊 レポート生成中...")
        
        try:
            # 既存のレポート生成スクリプトを使用
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
    parser = argparse.ArgumentParser(description="レジューム可能な外部LLM実験実行スクリプト")
    parser.add_argument("--external-llm-url", required=True, help="外部LLMサーバーのURL")
    parser.add_argument("--external-llm-model", required=True, help="外部LLMモデル名")
    parser.add_argument("--patterns", nargs="+", default=["chat_abs_json", "chat_persona_json", "chat_strict_json"], help="実行するパターン")
    parser.add_argument("--runs", type=int, default=20, help="各パターンの実行回数")
    parser.add_argument("--experiment-dir", help="実験ディレクトリ（指定しない場合は新規作成）")
    parser.add_argument("--generate-report", action="store_true", help="実験後にレポートを生成")
    
    args = parser.parse_args()
    
    # 実験実行
    runner = ResumableExternalLLMExperimentRunner(
        external_llm_url=args.external_llm_url,
        external_llm_model=args.external_llm_model,
        patterns=args.patterns,
        runs=args.runs,
        experiment_dir=args.experiment_dir
    )
    
    runner.run_experiment()
    
    # レポート生成
    if args.generate_report:
        runner.generate_report()

if __name__ == "__main__":
    main()
