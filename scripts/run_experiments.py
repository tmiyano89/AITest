#!/usr/bin/env python3
"""
拡張可能な実験実行スクリプト
複数のパターン、回数、言語を指定して実験を実行し、結果を一つのディレクトリに整理する
"""

import subprocess
import json
import statistics
import os
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any, Optional
import argparse

class ExperimentConfig:
    """実験設定クラス"""
    def __init__(self, pattern: str, language: str = "ja", runs: int = 1, mode: str = "simple"):
        self.pattern = pattern
        self.language = language
        self.runs = runs
        self.mode = mode

    def get_experiment_name(self) -> str:
        """実験名を生成"""
        return f"{self.pattern}_{self.language}_{self.mode}"

    def get_method(self) -> str:
        """抽出方法を取得"""
        if "_json" in self.pattern:
            return "json"
        elif "_generable" in self.pattern:
            return "generable"
        elif "_yaml" in self.pattern:
            return "yaml"
        else:
            return "generable"  # デフォルト

    def to_dict(self) -> Dict[str, Any]:
        """辞書形式に変換（JSONシリアライゼーション用）"""
        return {
            'pattern': self.pattern,
            'language': self.language,
            'runs': self.runs,
            'mode': self.mode,
            'experiment_name': self.get_experiment_name(),
            'method': self.get_method()
        }

class ExperimentRunner:
    """実験実行クラス"""
    
    def __init__(self, base_output_dir: str):
        self.base_output_dir = Path(base_output_dir)
        self.base_output_dir.mkdir(parents=True, exist_ok=True)
        self.results = []
    
    def run_single_experiment(self, config: ExperimentConfig) -> Optional[Dict[str, Any]]:
        """単一の実験設定をまとめて実行"""
        print(f"🔬 実験実行中: {config.get_experiment_name()} ({config.runs}回実行)")

        # 実験実行コマンド（新しい引数形式）
        # パターン名は {testcase}_{algo}_{method} の形式
        pattern_parts = config.pattern.split('_')
        testcase = pattern_parts[0]  # chat
        algo = pattern_parts[1]      # abs, strict, etc.
        method = pattern_parts[2]    # generable, json, yaml

        # ログファイル用のディレクトリを指定（全パターン共通）
        log_dir = str(self.base_output_dir)

        cmd = [
            "swift", "run", "AITestApp",
            "--method", method,
            "--mode", config.mode,
            "--testcase", testcase,
            "--algos", algo,
            "--language", config.language,
            "--runs", str(config.runs),
            "--test-dir", log_dir
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600, env=os.environ)
            if result.returncode != 0:
                print(f"❌ 実験失敗: {result.stderr}")
                return None
            
            return {
                'config': config,
                'success': True,
                'stdout': result.stdout,
                'stderr': result.stderr
            }
        except subprocess.TimeoutExpired:
            print(f"⏰ 実験タイムアウト")
            return None
        except Exception as e:
            print(f"❌ 実験例外: {e}")
            return None
    
    def run_experiments(self, configs: List[ExperimentConfig]) -> List[Dict[str, Any]]:
        """複数の実験設定を実行"""
        all_results = []
        
        # 総実験数を計算
        total_experiments = len(configs)
        completed_experiments = 0
        
        for config in configs:
            print(f"\n🚀 パターン {config.pattern} の実験を開始 ({config.runs}回実行)")
            print(f"📁 出力先: {self.base_output_dir}")
            
            # 進捗表示
            progress = (completed_experiments / total_experiments) * 100
            print(f"📊 進捗: {progress:.1f}% ({completed_experiments}/{total_experiments})")
            
            result = self.run_single_experiment(config)
            if result:
                all_results.append(result)
                self.results.append(result)
            
            completed_experiments += 1
        
        # 最終進捗表示
        print(f"📊 進捗: 100.0% ({completed_experiments}/{total_experiments}) - 完了!")
        
        return all_results
    
    def collect_log_files(self) -> List[Dict[str, Any]]:
        """ログファイルを収集"""
        log_data = []
        
        # ベースディレクトリ内のJSONファイルを検索（新しい命名規則のファイルのみ）
        json_files = list(self.base_output_dir.glob("*_level*_run*.json"))
        print(f"📁 ベースディレクトリ: {self.base_output_dir}")
        print(f"🔍 見つかったJSONファイル数: {len(json_files)}")
        
        for i, json_file in enumerate(json_files, 1):
            progress = (i / len(json_files)) * 100
            print(f"📄 処理中: {json_file.name} ({progress:.1f}%)")
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    log_data.append({
                        'file': str(json_file),
                        'data': data
                    })
                    print(f"✅ 読み込み成功: {json_file.name}")
            except Exception as e:
                print(f"❌ 読み込みエラー {json_file.name}: {e}")
        
        print(f"📊 ログファイル収集完了: {len(log_data)}/{len(json_files)} ファイル")
        return log_data
    
    def generate_statistics(self, log_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """統計を計算"""
        if not log_data:
            return {'error': 'ログデータがありません'}
        
        # パターン別の結果を整理
        pattern_results = {}
        
        for log in log_data:
            data = log['data']
            # 新しい構造に対応：個別のログファイルから直接データを取得
            pattern = data.get('experiment_pattern', 'unknown')
            if pattern not in pattern_results:
                pattern_results[pattern] = {
                    'correct': [],
                    'wrong': [],
                    'missing': [],
                    'unexpected': [],
                    'expected': [],
                    'test_cases': []
                }
            
            # expected_fieldsから期待項目数を計算
            expected_fields = data.get('expected_fields', [])
            expected_count = len(expected_fields)
            
            # correct, wrong, missing, unexpectedを計算
            correct_count = sum(1 for field in expected_fields if field.get('status') == 'correct')
            wrong_count = sum(1 for field in expected_fields if field.get('status') == 'wrong')
            missing_count = sum(1 for field in expected_fields if field.get('status') == 'missing')
            unexpected_count = len(data.get('unexpected_fields', []))
            
            pattern_results[pattern]['correct'].append(correct_count)
            pattern_results[pattern]['wrong'].append(wrong_count)
            pattern_results[pattern]['missing'].append(missing_count)
            pattern_results[pattern]['unexpected'].append(unexpected_count)
            pattern_results[pattern]['expected'].append(expected_count)
            pattern_results[pattern]['test_cases'].append(data)
        
        # 統計を計算
        stats = {}
        for pattern, results in pattern_results.items():
            if results['correct']:
                stats[pattern] = {
                    'total_test_cases': len(results['test_cases']),
                    'correct': {
                        'total': sum(results['correct']),
                        'mean': statistics.mean(results['correct']),
                        'std': statistics.stdev(results['correct']) if len(results['correct']) > 1 else 0
                    },
                    'wrong': {
                        'total': sum(results['wrong']),
                        'mean': statistics.mean(results['wrong']),
                        'std': statistics.stdev(results['wrong']) if len(results['wrong']) > 1 else 0
                    },
                    'missing': {
                        'total': sum(results['missing']),
                        'mean': statistics.mean(results['missing']),
                        'std': statistics.stdev(results['missing']) if len(results['missing']) > 1 else 0
                    },
                    'unexpected': {
                        'total': sum(results['unexpected']),
                        'mean': statistics.mean(results['unexpected']),
                        'std': statistics.stdev(results['unexpected']) if len(results['unexpected']) > 1 else 0
                    },
                    'expected': {
                        'total': sum(results['expected']),
                        'mean': statistics.mean(results['expected']),
                        'std': statistics.stdev(results['expected']) if len(results['expected']) > 1 else 0
                    }
                }
                
                # 正規化スコアを計算
                total_correct = stats[pattern]['correct']['total']
                total_wrong = stats[pattern]['wrong']['total']
                total_unexpected = stats[pattern]['unexpected']['total']
                total_expected = stats[pattern]['expected']['total']
                
                if total_expected > 0:
                    normalized_score = (total_correct - total_wrong - total_unexpected) / total_expected
                    stats[pattern]['normalized_score'] = normalized_score
                else:
                    stats[pattern]['normalized_score'] = 0
        
        return stats
    
    def generate_report(self, stats: Dict[str, Any]):
        """レポートを生成"""
        print("\n" + "="*80)
        print("📊 実験結果レポート")
        print("="*80)
        print(f"実行日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"出力ディレクトリ: {self.base_output_dir}")
        print()
        
        if 'error' in stats:
            print(f"❌ エラー: {stats['error']}")
            return
        
        for pattern, data in stats.items():
            print(f"🔍 パターン: {pattern}")
            print("-" * 40)
            print(f"テストケース数: {data['total_test_cases']}")
            print(f"正規化スコア: {data['normalized_score']:.4f}")
            print(f"正解項目数: {data['correct']['total']} (平均: {data['correct']['mean']:.1f} ± {data['correct']['std']:.1f})")
            print(f"誤り項目数: {data['wrong']['total']} (平均: {data['wrong']['mean']:.1f} ± {data['wrong']['std']:.1f})")
            print(f"不足項目数: {data['missing']['total']} (平均: {data['missing']['mean']:.1f} ± {data['missing']['std']:.1f})")
            print(f"余分項目数: {data['unexpected']['total']} (平均: {data['unexpected']['mean']:.1f} ± {data['unexpected']['std']:.1f})")
            print(f"期待項目数: {data['expected']['total']} (平均: {data['expected']['mean']:.1f} ± {data['expected']['std']:.1f})")
            print()
    
    def save_results(self, stats: Dict[str, Any], log_data: List[Dict[str, Any]]):
        """結果を保存"""
        output_file = self.base_output_dir / "experiment_results.json"
        
        # ExperimentConfigオブジェクトを辞書形式に変換
        serializable_results = []
        for result in self.results:
            serializable_result = result.copy()
            if 'config' in serializable_result:
                serializable_result['config'] = serializable_result['config'].to_dict()
            serializable_results.append(serializable_result)
        
        result_data = {
            'experiment_info': {
                'timestamp': datetime.now().isoformat(),
                'output_directory': str(self.base_output_dir),
                'total_experiments': len(self.results)
            },
            'statistics': stats,
            'raw_log_data': log_data,
            'experiment_results': serializable_results
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(result_data, f, ensure_ascii=False, indent=2)
        
        print(f"💾 結果を保存しました: {output_file}")

def main():
    """メイン処理（新しい引数方式）"""
    parser = argparse.ArgumentParser(description='拡張可能な実験実行スクリプト（新しい引数方式）')
    parser.add_argument('--method', default='generable', choices=['json', 'generable', 'yaml'],
                       help='抽出方法 (json/generable/yaml, デフォルト: generable)')
    parser.add_argument('--mode', default='simple', choices=['simple', 'two-steps'],
                       help='抽出モード (simple/two-steps, デフォルト: simple)')
    parser.add_argument('--testcases', nargs='+', default=['chat'],
                       choices=['chat', 'creditcard', 'contract', 'password', 'voice'],
                       help='テストケース (chat/creditcard/contract/password/voice, デフォルト: chat)')
    parser.add_argument('--algos', nargs='+',
                       default=['abs', 'strict', 'persona', 'abs-ex', 'strict-ex', 'persona-ex'],
                       choices=['abs', 'strict', 'persona', 'abs-ex', 'strict-ex', 'persona-ex'],
                       help='アルゴリズム (abs/strict/persona/abs-ex/strict-ex/persona-ex, デフォルト: すべて)')
    parser.add_argument('--levels', nargs='+', type=int, default=[1, 2, 3],
                       choices=[1, 2, 3],
                       help='レベル (1/2/3, デフォルト: 1,2,3)')
    parser.add_argument('--language', default='ja', choices=['ja', 'en'],
                       help='言語 (ja/en, デフォルト: ja)')
    parser.add_argument('--runs', type=int, default=1,
                       help='各パターンの実行回数 (デフォルト: 1)')
    parser.add_argument('--output-dir',
                       help='出力ディレクトリ (指定しない場合は自動生成)')

    args = parser.parse_args()

    # 出力ディレクトリを決定
    if args.output_dir:
        base_output_dir = args.output_dir
    else:
        timestamp = datetime.now().strftime("%Y%m%d%H%M")
        base_output_dir = f"test_logs/{timestamp}_{args.method}_{args.language}_{args.mode}"

    print("🚀 拡張可能な実験実行を開始します（新しい引数方式）...")
    print(f"🔧 抽出方法: {args.method}")
    print(f"🔄 抽出モード: {args.mode}")
    print(f"📋 テストケース: {', '.join(args.testcases)}")
    print(f"🧠 アルゴリズム: {', '.join(args.algos)}")
    print(f"📊 レベル: {', '.join(map(str, args.levels))}")
    print(f"🌐 言語: {args.language}")
    print(f"🔄 実行回数: {args.runs}回/パターン")
    print(f"📁 出力先: {base_output_dir}")
    print()

    # 実験設定を作成（すべての組み合わせを生成）
    configs = []
    for testcase in args.testcases:
        for algo in args.algos:
            for level in args.levels:
                # パターン名を生成: {testcase}_{algo}_{method}
                pattern = f"{testcase}_{algo}_{args.method}"
                config = ExperimentConfig(pattern=pattern, language=args.language, runs=args.runs, mode=args.mode)
                configs.append(config)
    
    # 実験実行
    runner = ExperimentRunner(base_output_dir)
    runner.run_experiments(configs)
    
    # ログファイルを収集
    print("\n📊 ログファイルを収集中...")
    log_data = runner.collect_log_files()
    
    # 統計を計算
    stats = runner.generate_statistics(log_data)
    
    # レポートを生成
    runner.generate_report(stats)
    
    # 結果を保存
    runner.save_results(stats, log_data)
    
    print(f"\n✅ 実験完了: {base_output_dir}")

if __name__ == "__main__":
    main()
