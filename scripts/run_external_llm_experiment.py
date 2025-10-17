#!/usr/bin/env python3
"""
@ai[2025-01-17 21:00] 外部LLM実験実行スクリプト
目的: 外部LLMサーバーを使用してFoundationModelsとの性能比較実験を実行
背景: ローカルLLM（gpt-oss-20b）との客観的性能比較が必要
意図: 同一テストケースで異なるLLMの性能を比較し、最適な選択指針を提供
"""

import subprocess
import sys
import os
import time
from datetime import datetime
from pathlib import Path
import json
import argparse

class ExternalLLMExperimentRunner:
    def __init__(self, external_llm_url: str, external_llm_model: str, patterns: list, runs: int = 20):
        self.external_llm_url = external_llm_url
        self.external_llm_model = external_llm_model
        self.patterns = patterns
        self.runs = runs
        self.experiment_dir = None
        
    def run_experiment(self):
        """外部LLM実験を実行"""
        print("🌐 外部LLM実験を開始します")
        print(f"   外部LLM URL: {self.external_llm_url}")
        print(f"   外部LLM モデル: {self.external_llm_model}")
        print(f"   パターン: {', '.join(self.patterns)}")
        print(f"   実行回数: {self.runs}")
        print("=" * 80)
        
        # 実験ディレクトリの作成
        timestamp = datetime.now().strftime("%Y%m%d%H%M")
        self.experiment_dir = f"test_logs/{timestamp}_external_llm_experiment"
        os.makedirs(self.experiment_dir, exist_ok=True)
        print(f"📁 実験ディレクトリ: {self.experiment_dir}")
        
        # 各パターンで実験を実行
        for pattern in self.patterns:
            print(f"\n🔬 パターン '{pattern}' の実験を開始")
            self.run_pattern_experiment(pattern)
        
        print(f"\n✅ 外部LLM実験完了")
        print(f"📁 結果ディレクトリ: {self.experiment_dir}")
        
    def run_pattern_experiment(self, pattern: str):
        """特定のパターンで実験を実行"""
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
        
        # 20回実行
        for run_num in range(1, self.runs + 1):
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
                    timeout=300  # 5分タイムアウト
                )
                
                if result.returncode == 0:
                    print(f"      ✅ 成功")
                else:
                    print(f"      ❌ 失敗: {result.stderr}")
                    
            except subprocess.TimeoutExpired:
                print(f"      ⏰ タイムアウト")
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
                "--log-dir", self.experiment_dir,
                "--output", f"{self.experiment_dir}/external_llm_report.html"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ レポート生成完了: {self.experiment_dir}/external_llm_report.html")
            else:
                print(f"❌ レポート生成失敗: {result.stderr}")
                
        except Exception as e:
            print(f"❌ レポート生成エラー: {e}")

def main():
    parser = argparse.ArgumentParser(description="外部LLM実験実行スクリプト")
    parser.add_argument("--external-llm-url", required=True, help="外部LLMサーバーのURL")
    parser.add_argument("--external-llm-model", required=True, help="外部LLMモデル名")
    parser.add_argument("--patterns", nargs="+", default=["chat_abs_json", "chat_persona_json", "chat_strict_json"], help="実行するパターン")
    parser.add_argument("--runs", type=int, default=20, help="各パターンの実行回数")
    parser.add_argument("--generate-report", action="store_true", help="実験後にレポートを生成")
    
    args = parser.parse_args()
    
    # 実験実行
    runner = ExternalLLMExperimentRunner(
        external_llm_url=args.external_llm_url,
        external_llm_model=args.external_llm_model,
        patterns=args.patterns,
        runs=args.runs
    )
    
    runner.run_experiment()
    
    # レポート生成
    if args.generate_report:
        runner.generate_report()

if __name__ == "__main__":
    main()
