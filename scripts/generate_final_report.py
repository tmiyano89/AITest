#!/usr/bin/env python3
"""
最終レポート生成スクリプト
AI分析結果を統合した最終レポートを生成する
"""

import json
import os
import sys
from datetime import datetime

def load_analysis(log_dir):
    """AI分析結果を読み込み"""
    analysis_file = os.path.join(log_dir, 'ai_analysis.json')
    if not os.path.exists(analysis_file):
        print(f"エラー: AI分析ファイルが見つかりません: {analysis_file}")
        return None
    
    with open(analysis_file, 'r', encoding='utf-8') as f:
        return json.load(f)

def generate_final_report_html(analysis, log_dir):
    """最終レポートのHTMLを生成"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    
    html_content = f"""
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FoundationModels 精度分析レポート - 最終版</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }}
        .header {{
            text-align: center;
            margin-bottom: 40px;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
        }}
        .section {{
            margin: 30px 0;
            padding: 20px;
            border-left: 4px solid #667eea;
            background: #f8f9fa;
        }}
        .analysis-box {{
            background: white;
            padding: 20px;
            margin: 15px 0;
            border-radius: 8px;
            border: 1px solid #e0e0e0;
        }}
        .metric-highlight {{
            background: #e3f2fd;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
        }}
        .recommendation {{
            background: #fff3e0;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
            border-left: 4px solid #ff9800;
        }}
        .hypothesis {{
            background: #f3e5f5;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
            border-left: 4px solid #9c27b0;
        }}
        .insight {{
            background: #e8f5e8;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
            border-left: 4px solid #4caf50;
        }}
        h1, h2, h3, h4 {{
            color: #333;
        }}
        .timestamp {{
            color: #666;
            font-size: 0.9em;
        }}
        ul {{
            padding-left: 20px;
        }}
        li {{
            margin: 8px 0;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧠 FoundationModels 精度分析レポート - AI分析版</h1>
            <p class="timestamp">生成日時: {timestamp}</p>
            <p>@ai[2024-12-19 18:30] AIによる詳細分析・考察・推奨事項を含む最終レポート</p>
        </div>
        
        <div class="section">
            <h2>📊 全体パフォーマンス概要</h2>
            <div class="metric-highlight">
                <h3>{analysis['overall_analysis']['summary']}</h3>
                <p><strong>主要メトリクス:</strong></p>
                <ul>
                    <li>期待項目数: {analysis['overall_analysis']['key_metrics']['expected_items']}</li>
                    <li>正解項目数: {analysis['overall_analysis']['key_metrics']['correct_items']}</li>
                    <li>誤り項目数: {analysis['overall_analysis']['key_metrics']['wrong_items']}</li>
                    <li>欠落項目数: {analysis['overall_analysis']['key_metrics']['missing_items']}</li>
                    <li>過剰項目数: {analysis['overall_analysis']['key_metrics']['unexpected_items']}</li>
                </ul>
            </div>
            
            <div class="insight">
                <h4>🔍 主要な洞察</h4>
                <ul>
"""
    
    for insight in analysis['overall_analysis']['insights']:
        html_content += f"                    <li>{insight}</li>\n"
    
    html_content += """
                </ul>
            </div>
        </div>
"""
    
    # 抽出方法別分析
    if analysis['method_analysis']:
        html_content += f"""
        <div class="section">
            <h2>🔧 抽出方法別詳細分析</h2>
            <div class="analysis-box">
                <h3>最良パフォーマンス: {analysis['method_analysis']['best_performer']['method']}</h3>
                <p><strong>正規化スコア:</strong> {analysis['method_analysis']['best_performer']['score']:.3f}</p>
                <ul>
                    <li>正解項目数: {analysis['method_analysis']['best_performer']['characteristics']['correct_items']}</li>
                    <li>誤り項目数: {analysis['method_analysis']['best_performer']['characteristics']['wrong_items']}</li>
                    <li>過剰項目数: {analysis['method_analysis']['best_performer']['characteristics']['unexpected_items']}</li>
                </ul>
            </div>
            
            <div class="analysis-box">
                <h3>最悪パフォーマンス: {analysis['method_analysis']['worst_performer']['method']}</h3>
                <p><strong>正規化スコア:</strong> {analysis['method_analysis']['worst_performer']['score']:.3f}</p>
                <ul>
                    <li>正解項目数: {analysis['method_analysis']['worst_performer']['characteristics']['correct_items']}</li>
                    <li>誤り項目数: {analysis['method_analysis']['worst_performer']['characteristics']['wrong_items']}</li>
                    <li>過剰項目数: {analysis['method_analysis']['worst_performer']['characteristics']['unexpected_items']}</li>
                </ul>
            </div>
            
            <div class="insight">
                <h4>🔍 分析結果</h4>
                <ul>
"""
        for insight in analysis['method_analysis']['insights']:
            html_content += f"                    <li>{insight}</li>\n"
        
        html_content += f"""
                </ul>
                <p><strong>性能差:</strong> {analysis['method_analysis']['performance_gap']:.3f}</p>
            </div>
        </div>
"""
    
    # 言語別分析
    if analysis['language_analysis']:
        html_content += f"""
        <div class="section">
            <h2>🌐 言語別詳細分析</h2>
            <div class="analysis-box">
                <h3>最良パフォーマンス: {analysis['language_analysis']['best_performer']['language']}</h3>
                <p><strong>正規化スコア:</strong> {analysis['language_analysis']['best_performer']['score']:.3f}</p>
            </div>
            
            <div class="analysis-box">
                <h3>最悪パフォーマンス: {analysis['language_analysis']['worst_performer']['language']}</h3>
                <p><strong>正規化スコア:</strong> {analysis['language_analysis']['worst_performer']['score']:.3f}</p>
            </div>
            
            <div class="insight">
                <h4>🔍 分析結果</h4>
                <ul>
"""
        for insight in analysis['language_analysis']['insights']:
            html_content += f"                    <li>{insight}</li>\n"
        
        html_content += f"""
                </ul>
                <p><strong>言語間差:</strong> {analysis['language_analysis']['language_gap']:.3f}</p>
            </div>
        </div>
"""
    
    # パターン別分析
    if analysis['pattern_analysis']:
        html_content += f"""
        <div class="section">
            <h2>📋 パターン別詳細分析</h2>
            <div class="analysis-box">
                <h3>最良パフォーマンス: {analysis['pattern_analysis']['best_performer']['pattern']}</h3>
                <p><strong>正規化スコア:</strong> {analysis['pattern_analysis']['best_performer']['score']:.3f}</p>
            </div>
            
            <div class="analysis-box">
                <h3>最悪パフォーマンス: {analysis['pattern_analysis']['worst_performer']['pattern']}</h3>
                <p><strong>正規化スコア:</strong> {analysis['pattern_analysis']['worst_performer']['score']:.3f}</p>
            </div>
            
            <div class="insight">
                <h4>🔍 分析結果</h4>
                <ul>
"""
        for insight in analysis['pattern_analysis']['insights']:
            html_content += f"                    <li>{insight}</li>\n"
        
        html_content += f"""
                </ul>
                <p><strong>パターン間差:</strong> {analysis['pattern_analysis']['pattern_gap']:.3f}</p>
            </div>
        </div>
"""
    
    # 推奨事項
    html_content += """
        <div class="section">
            <h2>💡 AI推奨事項</h2>
"""
    for i, recommendation in enumerate(analysis['recommendations'], 1):
        html_content += f"""
            <div class="recommendation">
                <h4>{i}. {recommendation}</h4>
            </div>
"""
    
    # 仮説
    html_content += """
        <div class="section">
            <h2>🔬 AI仮説</h2>
"""
    for i, hypothesis in enumerate(analysis['hypotheses'], 1):
        html_content += f"""
            <div class="hypothesis">
                <h4>{i}. {hypothesis}</h4>
            </div>
"""
    
    html_content += """
        </div>
        
        <div class="header">
            <h2>📊 AI分析完了</h2>
            <p>@ai[2024-12-19 18:30] FoundationModels 精度分析レポート - AI分析版</p>
            <p><strong>注意:</strong> このレポートはAIによる自動分析結果を含みます。実際の改善実装前には、さらなる検証が必要です。</p>
        </div>
    </div>
</body>
</html>
"""
    
    return html_content

def main():
    if len(sys.argv) != 2:
        print("使用方法: python3 scripts/generate_final_report.py <log_directory>")
        sys.exit(1)
    
    log_dir = sys.argv[1]
    if not os.path.exists(log_dir):
        print(f"エラー: ログディレクトリが見つかりません: {log_dir}")
        sys.exit(1)
    
    print(f"🔍 最終レポートを生成中: {log_dir}")
    
    # AI分析結果を読み込み
    analysis = load_analysis(log_dir)
    if not analysis:
        sys.exit(1)
    
    # 最終レポートのHTMLを生成
    html_content = generate_final_report_html(analysis, log_dir)
    
    # レポートを保存
    report_file = os.path.join(log_dir, 'final_ai_analysis_report.html')
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"✅ 最終レポートを生成しました: {report_file}")
    print(f"📖 レポートを表示: open {report_file}")

if __name__ == "__main__":
    main()
