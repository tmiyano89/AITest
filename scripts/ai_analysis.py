#!/usr/bin/env python3
"""
AI分析スクリプト
レポートの詳細分析と考察を追加する
"""

import json
import os
import sys
from datetime import datetime

def load_metrics(log_dir):
    """メトリクスファイルを読み込み"""
    metrics_file = os.path.join(log_dir, 'detailed_metrics.json')
    if not os.path.exists(metrics_file):
        print(f"エラー: メトリクスファイルが見つかりません: {metrics_file}")
        return None
    
    with open(metrics_file, 'r', encoding='utf-8') as f:
        return json.load(f)

def generate_ai_analysis(metrics):
    """AIによる詳細分析を生成"""
    analysis = {
        "timestamp": datetime.now().isoformat(),
        "overall_analysis": {},
        "method_analysis": {},
        "language_analysis": {},
        "pattern_analysis": {},
        "recommendations": [],
        "hypotheses": []
    }
    
    # 全体分析
    overall = metrics.get('item_metrics', {}).get('overall', {})
    analysis["overall_analysis"] = {
        "summary": f"全体正規化スコア: {overall.get('normalized_score', 0):.3f}",
        "key_metrics": {
            "expected_items": overall.get('expected_items', 0),
            "correct_items": overall.get('correct_items', 0),
            "wrong_items": overall.get('wrong_items', 0),
            "missing_items": overall.get('missing_items', 0),
            "unexpected_items": overall.get('unexpected_items', 0)
        },
        "insights": [
            f"正解率: {overall.get('correct_items', 0) / (overall.get('expected_items', 1) or 1) * 100:.1f}%",
            f"過剰抽出率: {overall.get('unexpected_items', 0) / (overall.get('expected_items', 1) or 1) * 100:.1f}%",
            f"欠落率: {overall.get('missing_items', 0) / (overall.get('expected_items', 1) or 1) * 100:.1f}%"
        ]
    }
    
    # 抽出方法別分析
    method_scores = metrics.get('grouped_scores', {}).get('by_method', {})
    if method_scores:
        best_method = max(method_scores.items(), key=lambda x: x[1]['normalized_score'])
        worst_method = min(method_scores.items(), key=lambda x: x[1]['normalized_score'])
        
        analysis["method_analysis"] = {
            "best_performer": {
                "method": best_method[0],
                "score": best_method[1]['normalized_score'],
                "characteristics": {
                    "correct_items": best_method[1]['correct_items'],
                    "wrong_items": best_method[1]['wrong_items'],
                    "unexpected_items": best_method[1]['unexpected_items']
                }
            },
            "worst_performer": {
                "method": worst_method[0],
                "score": worst_method[1]['normalized_score'],
                "characteristics": {
                    "correct_items": worst_method[1]['correct_items'],
                    "wrong_items": worst_method[1]['wrong_items'],
                    "unexpected_items": worst_method[1]['unexpected_items']
                }
            },
            "performance_gap": best_method[1]['normalized_score'] - worst_method[1]['normalized_score'],
            "insights": [
                f"{best_method[0]}が最も高い性能を示している",
                f"{worst_method[0]}の性能改善が必要",
                f"性能差は{best_method[1]['normalized_score'] - worst_method[1]['normalized_score']:.3f}"
            ]
        }
    
    # 言語別分析
    language_scores = metrics.get('grouped_scores', {}).get('by_language', {})
    if language_scores:
        best_lang = max(language_scores.items(), key=lambda x: x[1]['normalized_score'])
        worst_lang = min(language_scores.items(), key=lambda x: x[1]['normalized_score'])
        
        analysis["language_analysis"] = {
            "best_performer": {
                "language": best_lang[0],
                "score": best_lang[1]['normalized_score']
            },
            "worst_performer": {
                "language": worst_lang[0],
                "score": worst_lang[1]['normalized_score']
            },
            "language_gap": best_lang[1]['normalized_score'] - worst_lang[1]['normalized_score'],
            "insights": [
                f"{best_lang[0]}がより高い性能を示している",
                f"言語間の性能差は{best_lang[1]['normalized_score'] - worst_lang[1]['normalized_score']:.3f}",
                "言語固有の最適化が必要"
            ]
        }
    
    # パターン別分析
    pattern_scores = metrics.get('grouped_scores', {}).get('by_pattern', {})
    if pattern_scores:
        best_pattern = max(pattern_scores.items(), key=lambda x: x[1]['normalized_score'])
        worst_pattern = min(pattern_scores.items(), key=lambda x: x[1]['normalized_score'])
        
        analysis["pattern_analysis"] = {
            "best_performer": {
                "pattern": best_pattern[0],
                "score": best_pattern[1]['normalized_score']
            },
            "worst_performer": {
                "pattern": worst_pattern[0],
                "score": worst_pattern[1]['normalized_score']
            },
            "pattern_gap": best_pattern[1]['normalized_score'] - worst_pattern[1]['normalized_score'],
            "insights": [
                f"{best_pattern[0]}パターンが最も高い性能を示している",
                f"{worst_pattern[0]}パターンの改善が必要",
                "パターンの複雑さと性能の関係を分析する必要がある"
            ]
        }
    
    # 推奨事項
    analysis["recommendations"] = [
        "最良パフォーマンスの抽出方法の特性を他の方法に適用",
        "言語間の性能差を縮小するための最適化",
        "低性能パターンの段階的学習アプローチの検討",
        "過剰抽出率の削減のためのプロンプト改善",
        "欠落率の削減のための前処理改善"
    ]
    
    # 仮説
    analysis["hypotheses"] = [
        "抽出方法の性能差はプロンプト設計の違いによる",
        "言語間の性能差は文化的・言語的ニュアンスの違いによる",
        "パターンの複雑さが性能に影響している",
        "過剰抽出はモデルの創造性と精度のバランスの問題",
        "欠落はモデルの保守性と包括性のバランスの問題"
    ]
    
    return analysis

def save_analysis(analysis, log_dir):
    """分析結果を保存"""
    analysis_file = os.path.join(log_dir, 'ai_analysis.json')
    with open(analysis_file, 'w', encoding='utf-8') as f:
        json.dump(analysis, f, ensure_ascii=False, indent=2)
    print(f"✅ AI分析結果を保存しました: {analysis_file}")

def main():
    if len(sys.argv) != 2:
        print("使用方法: python3 scripts/ai_analysis.py <log_directory>")
        sys.exit(1)
    
    log_dir = sys.argv[1]
    if not os.path.exists(log_dir):
        print(f"エラー: ログディレクトリが見つかりません: {log_dir}")
        sys.exit(1)
    
    print(f"🔍 AI分析を開始: {log_dir}")
    
    # メトリクスを読み込み
    metrics = load_metrics(log_dir)
    if not metrics:
        sys.exit(1)
    
    # AI分析を生成
    analysis = generate_ai_analysis(metrics)
    
    # 分析結果を保存
    save_analysis(analysis, log_dir)
    
    print("✅ AI分析が完了しました")

if __name__ == "__main__":
    main()
