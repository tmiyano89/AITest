#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
@ai[2024-12-19 18:30] 統合レポート生成スクリプト（改良版）
目的: 構造化JSONログを解析して詳細な精度分析レポートを生成
背景: 項目の正解率、誤り率、値の正解率を正確に集計・分析
意図: AIモデルの挙動特徴、問題点、原因の詳細な考察を可能にする
"""

import os
import sys
import re
import json
from datetime import datetime
from pathlib import Path
from collections import defaultdict, Counter

def parse_log_file(log_file_path):
    """構造化JSONログファイルを解析して実験結果を抽出"""
    results = {
        'experiment': '',
        'method': '',
        'language': '',
        'test_cases': [],
        'summary': {
            'total_tests': 0,
            'successful': 0,
            'failed': 0,
            'timeout': False
        },
        'timing_stats': {
            'extraction_times': [],
            'avg_extraction_time': 0,
            'min_extraction_time': 0,
            'max_extraction_time': 0
        }
    }
    
    try:
        # JSONファイルの場合は直接解析
        if str(log_file_path).endswith('.json'):
            return parse_json_file(log_file_path)
        
        # ログファイルの場合は従来の処理
        with open(log_file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # 実験名を抽出
        experiment_match = re.search(r'format_experiment_(\w+)_(\w+)\.log', log_file_path)
        if experiment_match:
            method, language = experiment_match.groups()
            results['experiment'] = f"{method}_{language}"
            results['method'] = method
            results['language'] = language
        
        # タイムアウトチェック
        if "タイムアウト" in content or "timeout" in content.lower():
            results['summary']['timeout'] = True
        
        # 構造化JSONログを抽出
        # より正確なJSON抽出のための正規表現
        json_pattern = r'📊 構造化ログ:\s*\n(\{.*?\})\n(?=📋|📊|💾|$)'
        json_matches = re.findall(json_pattern, content, re.DOTALL)
        
        # デバッグ: 正規表現がマッチしない場合の代替手段
        if not json_matches:
            # より単純なパターンで試す
            json_pattern = r'📊 構造化ログ:\s*\n(\{.*?\})'
            json_matches = re.findall(json_pattern, content, re.DOTALL)
        
        # さらにデバッグ: 完全なJSONを抽出する
        if not json_matches:
            # 行ごとに分割してJSONの開始と終了を検出
            lines = content.split('\n')
            in_json = False
            json_lines = []
            for line in lines:
                if '📊 構造化ログ:' in line:
                    in_json = True
                    json_lines = []
                elif in_json:
                    if line.strip() == '}':
                        json_lines.append(line)
                        json_str = '\n'.join(json_lines)
                        json_matches.append(json_str)
                        in_json = False
                        json_lines = []
                    else:
                        json_lines.append(line)
        
        # 正規表現で抽出されたJSONが不完全な場合の修正
        try:
            if json_matches and any('JSON解析エラー' in str(e) for e in [json.loads(j) for j in json_matches if j]):
                # 行ごとに分割してJSONの開始と終了を検出
                lines = content.split('\n')
                in_json = False
                json_lines = []
                json_matches = []
                for line in lines:
                    if '📊 構造化ログ:' in line:
                        in_json = True
                        json_lines = []
                    elif in_json:
                        if line.strip() == '}':
                            json_lines.append(line)
                            json_str = '\n'.join(json_lines)
                            json_matches.append(json_str)
                            in_json = False
                            json_lines = []
                        else:
                            json_lines.append(line)
        except:
            pass
        
        print(f"  抽出されたJSON数: {len(json_matches)}")
        for i, json_str in enumerate(json_matches):
            print(f"  JSON {i+1}: {json_str[:100]}...")
            try:
                structured_data = json.loads(json_str)
                test_result = {
                    'pattern': structured_data.get('pattern', ''),
                    'level': structured_data.get('level', 0),
                    'iteration': structured_data.get('iteration', 0),
                    'method': structured_data.get('method', ''),
                    'language': structured_data.get('language', ''),
                    'expected_fields': structured_data.get('expected_fields', []),
                    'unexpected_fields': structured_data.get('unexpected_fields', []),
                    'error': structured_data.get('error', None),
                    'extraction_time': structured_data.get('extraction_time', 0)
                }
                
                # 抽出時間の統計を更新
                if 'extraction_time' in structured_data and structured_data['extraction_time'] > 0:
                    results['timing_stats']['extraction_times'].append(structured_data['extraction_time'])
                
                results['test_cases'].append(test_result)
                results['summary']['total_tests'] += 1
                
                if structured_data.get('error'):
                    results['summary']['failed'] += 1
                else:
                    results['summary']['successful'] += 1
                    
            except json.JSONDecodeError as e:
                print(f"JSON解析エラー: {e}")
                print(f"問題のJSON: {json_str[:200]}...")
                continue
            
    except Exception as e:
        print(f"エラー: ログファイル {log_file_path} の解析に失敗: {e}")
    
    return results

def parse_json_file(json_file_path):
    """JSONファイルを直接解析"""
    results = {
        'experiment': '',
        'method': '',
        'language': '',
        'test_cases': [],
        'summary': {
            'total_tests': 0,
            'successful': 0,
            'failed': 0,
            'timeout': False
        },
        'timing_stats': {
            'extraction_times': [],
            'avg_extraction_time': 0,
            'min_extraction_time': 0,
            'max_extraction_time': 0
        }
    }
    
    try:
        with open(json_file_path, 'r', encoding='utf-8') as f:
            structured_data = json.load(f)
        
        # 実験名を抽出（ファイル名から）
        file_name = Path(json_file_path).stem  # 拡張子を除いたファイル名
        # ファイル名の形式: {method}_{language}_{pattern}_level{level}_{iteration}
        parts = file_name.split('_')
        if len(parts) >= 2:
            method = parts[0]
            language = parts[1]
            results['experiment'] = f"{method}_{language}"
            results['method'] = method
            results['language'] = language
        
        # テストケースとして追加
        test_result = {
            'pattern': structured_data.get('pattern', ''),
            'level': structured_data.get('level', 0),
            'iteration': structured_data.get('iteration', 0),
            'method': structured_data.get('method', ''),
            'language': structured_data.get('language', ''),
            'expected_fields': structured_data.get('expected_fields', []),
            'unexpected_fields': structured_data.get('unexpected_fields', []),
            'error': structured_data.get('error', None),
            'extraction_time': structured_data.get('extraction_time', 0)
        }
        
        # 抽出時間の統計を更新
        if 'extraction_time' in structured_data and structured_data['extraction_time'] > 0:
            results['timing_stats']['extraction_times'].append(structured_data['extraction_time'])
        
        results['test_cases'].append(test_result)
        results['summary']['total_tests'] += 1
        
        if structured_data.get('error'):
            results['summary']['failed'] += 1
        else:
            results['summary']['successful'] += 1
            
    except Exception as e:
        print(f"エラー: JSONファイル {json_file_path} の解析に失敗: {e}")
    
    return results

def calculate_accuracy_metrics(all_results):
    """精度メトリクスを計算"""
    metrics = {
        'by_experiment': {},
        'by_pattern': defaultdict(lambda: {'correct': 0, 'wrong': 0, 'missing': 0, 'unexpected': 0, 'pending': 0}),
        'by_field': defaultdict(lambda: {'correct': 0, 'wrong': 0, 'missing': 0, 'unexpected': 0, 'pending': 0}),
        'by_level': defaultdict(lambda: {'correct': 0, 'wrong': 0, 'missing': 0, 'unexpected': 0, 'pending': 0}),
        'by_pattern_level': defaultdict(lambda: defaultdict(lambda: {'correct': 0, 'wrong': 0, 'missing': 0, 'unexpected': 0, 'pending': 0})),
        'overall': {'correct': 0, 'wrong': 0, 'missing': 0, 'unexpected': 0, 'pending': 0}
    }
    
    for result in all_results:
        experiment = result['experiment']
        method = result['method']
        language = result['language']
        
        if experiment not in metrics['by_experiment']:
            metrics['by_experiment'][experiment] = {
                'method': method,
                'language': language,
                'correct': 0, 'wrong': 0, 'missing': 0, 'unexpected': 0, 'pending': 0
            }
        
        for test_case in result['test_cases']:
            pattern = test_case['pattern']
            level = test_case['level']
            
            # 期待フィールドの分析
            for field in test_case['expected_fields']:
                status = field['status']
                field_name = field['name']
                
                metrics['by_experiment'][experiment][status] += 1
                metrics['by_pattern'][pattern][status] += 1
                metrics['by_field'][field_name][status] += 1
                metrics['by_level'][level][status] += 1
                metrics['by_pattern_level'][pattern][level][status] += 1
                metrics['overall'][status] += 1
            
            # 期待されないフィールドの分析
            for field in test_case['unexpected_fields']:
                status = 'unexpected'
                field_name = field['name']
                
                metrics['by_experiment'][experiment][status] += 1
                metrics['by_pattern'][pattern][status] += 1
                metrics['by_field'][field_name][status] += 1
                metrics['by_level'][level][status] += 1
                metrics['by_pattern_level'][pattern][level][status] += 1
                metrics['overall'][status] += 1
    
    return metrics

def calculate_item_based_metrics(all_results):
    """項目数ベースのメトリクスを計算"""
    item_metrics = {
        'by_pattern_level': {},
        'by_pattern': {},
        'by_level': {},
        'overall': {
            'expected_items': 0,
            'correct_items': 0,
            'wrong_items': 0,
            'missing_items': 0,
            'unexpected_items': 0
        }
    }
    
    for result in all_results:
        for test_case in result['test_cases']:
            pattern = test_case['pattern']
            level = test_case['level']
            
            # 期待フィールド数
            expected_count = len(test_case['expected_fields'])
            # 実際の抽出結果
            correct_count = sum(1 for field in test_case['expected_fields'] if field['status'] == 'correct')
            wrong_count = sum(1 for field in test_case['expected_fields'] if field['status'] == 'wrong')
            missing_count = sum(1 for field in test_case['expected_fields'] if field['status'] == 'missing')
            unexpected_count = len(test_case['unexpected_fields'])

            # 整合性保証: 期待 = 正解 + 誤り + 欠落
            # 欠落が未集計なケースに備えて丸める
            accounted = correct_count + wrong_count + missing_count
            if accounted > expected_count:
                # 異常値の場合はwrong_countを減らして合わせる（最小限の補正）
                overflow = accounted - expected_count
                wrong_count = max(0, wrong_count - overflow)
                accounted = correct_count + wrong_count + missing_count
            if accounted < expected_count:
                # 欠落に不足分を反映
                missing_count += (expected_count - accounted)
            
            # パターン・レベル別の集計
            if pattern not in item_metrics['by_pattern_level']:
                item_metrics['by_pattern_level'][pattern] = {}
            if level not in item_metrics['by_pattern_level'][pattern]:
                item_metrics['by_pattern_level'][pattern][level] = {
                    'expected_items': 0,
                    'correct_items': 0,
                    'wrong_items': 0,
                    'missing_items': 0,
                    'unexpected_items': 0,
                    'test_cases': 0
                }
            
            item_metrics['by_pattern_level'][pattern][level]['expected_items'] += expected_count
            item_metrics['by_pattern_level'][pattern][level]['correct_items'] += correct_count
            item_metrics['by_pattern_level'][pattern][level]['wrong_items'] += wrong_count
            item_metrics['by_pattern_level'][pattern][level]['missing_items'] += missing_count
            item_metrics['by_pattern_level'][pattern][level]['unexpected_items'] += unexpected_count
            item_metrics['by_pattern_level'][pattern][level]['test_cases'] += 1
            
            # パターン別の集計
            if pattern not in item_metrics['by_pattern']:
                item_metrics['by_pattern'][pattern] = {
                    'expected_items': 0,
                    'correct_items': 0,
                    'wrong_items': 0,
                    'missing_items': 0,
                    'unexpected_items': 0,
                    'test_cases': 0
                }
            
            item_metrics['by_pattern'][pattern]['expected_items'] += expected_count
            item_metrics['by_pattern'][pattern]['correct_items'] += correct_count
            item_metrics['by_pattern'][pattern]['wrong_items'] += wrong_count
            item_metrics['by_pattern'][pattern]['missing_items'] += missing_count
            item_metrics['by_pattern'][pattern]['unexpected_items'] += unexpected_count
            item_metrics['by_pattern'][pattern]['test_cases'] += 1
            
            # レベル別の集計
            if level not in item_metrics['by_level']:
                item_metrics['by_level'][level] = {
                    'expected_items': 0,
                    'correct_items': 0,
                    'wrong_items': 0,
                    'missing_items': 0,
                    'unexpected_items': 0,
                    'test_cases': 0
                }
            
            item_metrics['by_level'][level]['expected_items'] += expected_count
            item_metrics['by_level'][level]['correct_items'] += correct_count
            item_metrics['by_level'][level]['wrong_items'] += wrong_count
            item_metrics['by_level'][level]['missing_items'] += missing_count
            item_metrics['by_level'][level]['unexpected_items'] += unexpected_count
            item_metrics['by_level'][level]['test_cases'] += 1
            
            # 全体の集計
            item_metrics['overall']['expected_items'] += expected_count
            item_metrics['overall']['correct_items'] += correct_count
            item_metrics['overall']['wrong_items'] += wrong_count
            item_metrics['overall']['missing_items'] += missing_count
            item_metrics['overall']['unexpected_items'] += unexpected_count
    
    return item_metrics

def compute_grouped_item_scores(all_results):
    """method/language/patternの各軸で、項目数ベースと正規化スコアを集計"""
    def ensure_group(d):
        if 'expected_items' not in d:
            d.update({'expected_items':0,'correct_items':0,'wrong_items':0,'missing_items':0,'unexpected_items':0,'tests':0})

    by_method = {}
    by_language = {}
    by_pattern = {}

    for result in all_results:
        for tc in result['test_cases']:
            expected = len(tc.get('expected_fields', []))
            correct = sum(1 for f in tc.get('expected_fields', []) if f.get('status')=='correct')
            wrong = sum(1 for f in tc.get('expected_fields', []) if f.get('status')=='wrong')
            missing = sum(1 for f in tc.get('expected_fields', []) if f.get('status')=='missing')
            unexpected = len(tc.get('unexpected_fields', []))
            # 整合性
            accounted = correct + wrong + missing
            if accounted > expected:
                overflow = accounted - expected
                wrong = max(0, wrong - overflow)
                accounted = correct + wrong + missing
            if accounted < expected:
                missing += (expected - accounted)

            meth = tc.get('method') or result.get('method')
            lang = tc.get('language') or result.get('language')
            patt = tc.get('pattern')

            if meth:
                by_method.setdefault(meth, {}); ensure_group(by_method[meth])
                g = by_method[meth]; g['expected_items']+=expected; g['correct_items']+=correct; g['wrong_items']+=wrong; g['missing_items']+=missing; g['unexpected_items']+=unexpected; g['tests']+=1
            if lang:
                by_language.setdefault(lang, {}); ensure_group(by_language[lang])
                g = by_language[lang]; g['expected_items']+=expected; g['correct_items']+=correct; g['wrong_items']+=wrong; g['missing_items']+=missing; g['unexpected_items']+=unexpected; g['tests']+=1
            if patt:
                by_pattern.setdefault(patt, {}); ensure_group(by_pattern[patt])
                g = by_pattern[patt]; g['expected_items']+=expected; g['correct_items']+=correct; g['wrong_items']+=wrong; g['missing_items']+=missing; g['unexpected_items']+=unexpected; g['tests']+=1

    def add_score(dct):
        out = {}
        for k,v in dct.items():
            exp = v['expected_items'] or 1
            score = (v['correct_items'] - v['wrong_items'] - v['unexpected_items']) / exp
            out[k] = {**v, 'normalized_score': score}
        return out

    return {
        'by_method': add_score(by_method),
        'by_language': add_score(by_language),
        'by_pattern': add_score(by_pattern),
    }

def calculate_rates(metrics):
    """各種率を計算"""
    rates = {
        'overall': {},
        'by_experiment': {},
        'by_pattern': {},
        'by_field': {},
        'by_pattern_level': {}
    }
    
    # 全体の率
    total = sum(metrics['overall'].values())
    if total > 0:
        # 過剰抽出率は抽出すべき項目数に対する比率（100%を超えることがある）
        expected_total = metrics['overall']['correct'] + metrics['overall']['wrong'] + metrics['overall']['missing']
        unexpected_rate = metrics['overall']['unexpected'] / expected_total if expected_total > 0 else 0
        
        # pending項目を除いた総数で正解率を計算
        evaluable_total = metrics['overall']['correct'] + metrics['overall']['wrong'] + metrics['overall']['missing'] + metrics['overall']['unexpected']
        
        rates['overall'] = {
            'correct_rate': metrics['overall']['correct'] / evaluable_total if evaluable_total > 0 else 0,
            'wrong_rate': metrics['overall']['wrong'] / evaluable_total if evaluable_total > 0 else 0,
            'missing_rate': metrics['overall']['missing'] / evaluable_total if evaluable_total > 0 else 0,
            'unexpected_rate': unexpected_rate,
            'pending_rate': metrics['overall']['pending'] / total,
            'precision': metrics['overall']['correct'] / (metrics['overall']['correct'] + metrics['overall']['wrong'] + metrics['overall']['unexpected']) if (metrics['overall']['correct'] + metrics['overall']['wrong'] + metrics['overall']['unexpected']) > 0 else 0,
            'recall': metrics['overall']['correct'] / (metrics['overall']['correct'] + metrics['overall']['missing']) if (metrics['overall']['correct'] + metrics['overall']['missing']) > 0 else 0
        }
    else:
        # データがない場合のデフォルト値
        rates['overall'] = {
            'correct_rate': 0.0,
            'wrong_rate': 0.0,
            'missing_rate': 0.0,
            'unexpected_rate': 0.0,
            'pending_rate': 0.0,
            'precision': 0.0,
            'recall': 0.0
        }
    
    # 実験別の率
    rates['by_experiment'] = {}
    for experiment, data in metrics['by_experiment'].items():
        # methodとlanguageを除外して数値のみを合計
        numeric_data = {k: v for k, v in data.items() if isinstance(v, int)}
        total = sum(numeric_data.values())
        if total > 0:
            # 過剰抽出率は抽出すべき項目数に対する比率
            expected_total = data['correct'] + data['wrong'] + data['missing']
            unexpected_rate = data['unexpected'] / expected_total if expected_total > 0 else 0
            
            # pending項目を除いた総数で正解率を計算
            evaluable_total = data['correct'] + data['wrong'] + data['missing'] + data['unexpected']
            
            rates['by_experiment'][experiment] = {
                'correct_rate': data['correct'] / evaluable_total if evaluable_total > 0 else 0,
                'wrong_rate': data['wrong'] / evaluable_total if evaluable_total > 0 else 0,
                'missing_rate': data['missing'] / evaluable_total if evaluable_total > 0 else 0,
                'unexpected_rate': unexpected_rate,
                'pending_rate': data['pending'] / total,
                'precision': data['correct'] / (data['correct'] + data['wrong'] + data['unexpected']) if (data['correct'] + data['wrong'] + data['unexpected']) > 0 else 0,
                'recall': data['correct'] / (data['correct'] + data['missing']) if (data['correct'] + data['missing']) > 0 else 0
            }
    
    # パターン別の率
    rates['by_pattern'] = {}
    for pattern, data in metrics['by_pattern'].items():
        total = sum(data.values())
        if total > 0:
            # 過剰抽出率は抽出すべき項目数に対する比率
            expected_total = data['correct'] + data['wrong'] + data['missing']
            unexpected_rate = data['unexpected'] / expected_total if expected_total > 0 else 0
            
            # pending項目を除いた総数で正解率を計算
            evaluable_total = data['correct'] + data['wrong'] + data['missing'] + data['unexpected']
            
            rates['by_pattern'][pattern] = {
                'correct_rate': data['correct'] / evaluable_total if evaluable_total > 0 else 0,
                'wrong_rate': data['wrong'] / evaluable_total if evaluable_total > 0 else 0,
                'missing_rate': data['missing'] / evaluable_total if evaluable_total > 0 else 0,
                'unexpected_rate': unexpected_rate,
                'pending_rate': data['pending'] / total,
                'precision': data['correct'] / (data['correct'] + data['wrong'] + data['unexpected']) if (data['correct'] + data['wrong'] + data['unexpected']) > 0 else 0,
                'recall': data['correct'] / (data['correct'] + data['missing']) if (data['correct'] + data['missing']) > 0 else 0
            }
    
    # レベル別の率
    rates['by_level'] = {}
    for level, data in metrics['by_level'].items():
        total = sum(data.values())
        if total > 0:
            # 過剰抽出率は抽出すべき項目数に対する比率
            expected_total = data['correct'] + data['wrong'] + data['missing']
            unexpected_rate = data['unexpected'] / expected_total if expected_total > 0 else 0
            
            # pending項目を除いた総数で正解率を計算
            evaluable_total = data['correct'] + data['wrong'] + data['missing'] + data['unexpected']
            
            rates['by_level'][level] = {
                'correct_rate': data['correct'] / evaluable_total if evaluable_total > 0 else 0,
                'wrong_rate': data['wrong'] / evaluable_total if evaluable_total > 0 else 0,
                'missing_rate': data['missing'] / evaluable_total if evaluable_total > 0 else 0,
                'unexpected_rate': unexpected_rate,
                'pending_rate': data['pending'] / total,
                'precision': data['correct'] / (data['correct'] + data['wrong'] + data['unexpected']) if (data['correct'] + data['wrong'] + data['unexpected']) > 0 else 0,
                'recall': data['correct'] / (data['correct'] + data['missing']) if (data['correct'] + data['missing']) > 0 else 0
            }
    
    # フィールド別の率
    rates['by_field'] = {}
    for field, data in metrics['by_field'].items():
        total = sum(data.values())
        if total > 0:
            # 過剰抽出率は抽出すべき項目数に対する比率
            expected_total = data['correct'] + data['wrong'] + data['missing']
            unexpected_rate = data['unexpected'] / expected_total if expected_total > 0 else 0
            
            # pending項目を除いた総数で正解率を計算
            evaluable_total = data['correct'] + data['wrong'] + data['missing'] + data['unexpected']
            
            rates['by_field'][field] = {
                'correct_rate': data['correct'] / evaluable_total if evaluable_total > 0 else 0,
                'wrong_rate': data['wrong'] / evaluable_total if evaluable_total > 0 else 0,
                'missing_rate': data['missing'] / evaluable_total if evaluable_total > 0 else 0,
                'unexpected_rate': unexpected_rate,
                'pending_rate': data['pending'] / total,
                'precision': data['correct'] / (data['correct'] + data['wrong'] + data['unexpected']) if (data['correct'] + data['wrong'] + data['unexpected']) > 0 else 0,
                'recall': data['correct'] / (data['correct'] + data['missing']) if (data['correct'] + data['missing']) > 0 else 0
            }
    
    # パターン・レベル別の率
    rates['by_pattern_level'] = {}
    for pattern, level_data in metrics['by_pattern_level'].items():
        rates['by_pattern_level'][pattern] = {}
        for level, data in level_data.items():
            total = sum(data.values())
            if total > 0:
                # 過剰抽出率は抽出すべき項目数に対する比率
                expected_total = data['correct'] + data['wrong'] + data['missing']
                unexpected_rate = data['unexpected'] / expected_total if expected_total > 0 else 0
                
                # pending項目を除いた総数で正解率を計算
                evaluable_total = data['correct'] + data['wrong'] + data['missing'] + data['unexpected']
                
                rates['by_pattern_level'][pattern][level] = {
                    'correct_rate': data['correct'] / evaluable_total if evaluable_total > 0 else 0,
                    'wrong_rate': data['wrong'] / evaluable_total if evaluable_total > 0 else 0,
                    'missing_rate': data['missing'] / evaluable_total if evaluable_total > 0 else 0,
                    'unexpected_rate': unexpected_rate,
                    'pending_rate': data['pending'] / total,
                    'precision': data['correct'] / (data['correct'] + data['wrong'] + data['unexpected']) if (data['correct'] + data['wrong'] + data['unexpected']) > 0 else 0,
                    'recall': data['correct'] / (data['correct'] + data['missing']) if (data['correct'] + data['missing']) > 0 else 0
                }
    
    return rates

def calculate_timing_stats(all_results):
    """抽出時間の統計を計算"""
    timing_stats = {
        'overall': {
            'extraction_times': [],
            'avg_extraction_time': 0,
            'min_extraction_time': 0,
            'max_extraction_time': 0,
            'total_extraction_time': 0,
            'test_case_count': 0,
            'total_extraction_count': 0
        },
        'by_experiment': {},
        'by_pattern': {},
        'by_level': {},
        'by_pattern_level': {}
    }
    
    all_times = []
    
    for result in all_results:
        experiment = result['experiment']
        method = result['method']
        language = result['language']
        
        # 実験別の統計
        if experiment not in timing_stats['by_experiment']:
            timing_stats['by_experiment'][experiment] = {
                'extraction_times': [],
                'avg_extraction_time': 0,
                'min_extraction_time': 0,
                'max_extraction_time': 0,
                'total_extraction_time': 0,
                'method': method,
                'language': language
            }
        
        # 各テストケースの抽出時間を収集
        for test_case in result['test_cases']:
            if 'extraction_time' in test_case and test_case['extraction_time'] > 0:
                extraction_time = test_case['extraction_time']
                all_times.append(extraction_time)
                timing_stats['by_experiment'][experiment]['extraction_times'].append(extraction_time)
                
                # パターン別の統計
                pattern = test_case['pattern']
                if pattern not in timing_stats['by_pattern']:
                    timing_stats['by_pattern'][pattern] = {
                        'extraction_times': [],
                        'avg_extraction_time': 0,
                        'min_extraction_time': 0,
                        'max_extraction_time': 0,
                        'total_extraction_time': 0
                    }
                timing_stats['by_pattern'][pattern]['extraction_times'].append(extraction_time)
                
                # レベル別の統計
                level = test_case['level']
                if level not in timing_stats['by_level']:
                    timing_stats['by_level'][level] = {
                        'extraction_times': [],
                        'avg_extraction_time': 0,
                        'min_extraction_time': 0,
                        'max_extraction_time': 0,
                        'total_extraction_time': 0
                    }
                timing_stats['by_level'][level]['extraction_times'].append(extraction_time)
                
                # パターン・レベル別の統計
                if pattern not in timing_stats['by_pattern_level']:
                    timing_stats['by_pattern_level'][pattern] = {}
                if level not in timing_stats['by_pattern_level'][pattern]:
                    timing_stats['by_pattern_level'][pattern][level] = {
                        'extraction_times': [],
                        'avg_extraction_time': 0,
                        'min_extraction_time': 0,
                        'max_extraction_time': 0,
                        'total_extraction_time': 0,
                        'test_case_count': 0
                    }
                timing_stats['by_pattern_level'][pattern][level]['extraction_times'].append(extraction_time)
    
    # 全体の統計を計算
    total_test_cases = 0
    total_extraction_count = 0
    
    for result in all_results:
        total_test_cases += len(result['test_cases'])
        for test_case in result['test_cases']:
            total_extraction_count += len(test_case['expected_fields']) + len(test_case['unexpected_fields'])
    
    timing_stats['overall']['test_case_count'] = total_test_cases
    timing_stats['overall']['total_extraction_count'] = total_extraction_count
    
    if all_times:
        timing_stats['overall']['extraction_times'] = all_times
        timing_stats['overall']['avg_extraction_time'] = sum(all_times) / len(all_times)
        timing_stats['overall']['min_extraction_time'] = min(all_times)
        timing_stats['overall']['max_extraction_time'] = max(all_times)
        timing_stats['overall']['total_extraction_time'] = sum(all_times)
    
    # 各カテゴリの統計を計算
    for category in ['by_experiment', 'by_pattern', 'by_level']:
        for key, data in timing_stats[category].items():
            if data['extraction_times']:
                data['avg_extraction_time'] = sum(data['extraction_times']) / len(data['extraction_times'])
                data['min_extraction_time'] = min(data['extraction_times'])
                data['max_extraction_time'] = max(data['extraction_times'])
                data['total_extraction_time'] = sum(data['extraction_times'])
    
    # パターン・レベル別の統計を計算
    for pattern, level_data in timing_stats['by_pattern_level'].items():
        for level, data in level_data.items():
            if data['extraction_times']:
                data['avg_extraction_time'] = sum(data['extraction_times']) / len(data['extraction_times'])
                data['min_extraction_time'] = min(data['extraction_times'])
                data['max_extraction_time'] = max(data['extraction_times'])
                data['total_extraction_time'] = sum(data['extraction_times'])
                data['test_case_count'] = len(data['extraction_times'])
    
    return timing_stats

def generate_html_report(all_results, output_path, rates=None, timing_stats=None, item_metrics=None):
    """詳細な精度分析HTMLレポートを生成"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # 精度メトリクスを計算（引数で渡されていない場合のみ）
    if rates is None:
        metrics = calculate_accuracy_metrics(all_results)
        rates = calculate_rates(metrics)
    else:
        # ratesが渡された場合でも、metricsは必要
        metrics = calculate_accuracy_metrics(all_results)
    
    # 項目数ベースのメトリクスを計算（引数で渡されていない場合のみ）
    if item_metrics is None:
        item_metrics = calculate_item_based_metrics(all_results)
    grouped_scores = compute_grouped_item_scores(all_results)
    
    if timing_stats is None:
        timing_stats = calculate_timing_stats(all_results)
    
    # データが不足している場合の処理
    if 'overall' not in rates:
        html_content = f"""
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FoundationModels 精度分析レポート</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }}
        .error {{ background: #f8d7da; color: #721c24; padding: 20px; border-radius: 8px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🔬 FoundationModels 精度分析レポート</h1>
        <p>生成日時: {timestamp}</p>
        <p>実験数: {len(all_results)}</p>
    </div>
    
    <div class="error">
        <h2>⚠️ データ不足エラー</h2>
        <p>JSONログの抽出に問題があります。構造化ログが正しく生成されていない可能性があります。</p>
        <p>ログファイルを確認して、AITestAppが正しく動作していることを確認してください。</p>
    </div>
</body>
</html>
"""
    else:
        html_content = f"""
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FoundationModels 精度分析レポート</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }}
        .summary {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }}
        .summary-card {{ background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; }}
        .metrics-table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        .metrics-table th, .metrics-table td {{ border: 1px solid #ddd; padding: 8px; text-align: center; }}
        .metrics-table th {{ background: #f8f9fa; font-weight: bold; }}
        .correct {{ color: #28a745; font-weight: bold; }}
        .wrong {{ color: #dc3545; font-weight: bold; }}
        .missing {{ color: #ffc107; font-weight: bold; }}
        .unexpected {{ color: #6f42c1; font-weight: bold; }}
        .pending {{ color: #17a2b8; font-weight: bold; }}
        .section {{ margin: 30px 0; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }}
        .section h3 {{ margin-top: 0; color: #333; }}
        .chart-container {{ position: relative; height: 400px; margin: 20px 0; }}
        .chart-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); gap: 20px; }}
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="header">
        <h1>🔬 FoundationModels 精度分析レポート</h1>
        <p>生成日時: {timestamp}</p>
        <p>実験数: {len(all_results)}</p>
    </div>
    
    <div class="summary">
        <div class="summary-card">
            <h3>総期待項目数</h3>
            <p style="font-size: 2em; margin: 0;">{item_metrics['overall']['expected_items']}</p>
        </div>
        <div class="summary-card">
            <h3>総正解項目数</h3>
            <p style="font-size: 2em; margin: 0; color: #28a745;">{item_metrics['overall']['correct_items']}</p>
        </div>
        <div class="summary-card">
            <h3>総誤り項目数</h3>
            <p style="font-size: 2em; margin: 0; color: #dc3545;">{item_metrics['overall']['wrong_items']}</p>
        </div>
        <div class="summary-card">
            <h3>総欠落項目数</h3>
            <p style="font-size: 2em; margin: 0; color: #ffc107;">{item_metrics['overall']['missing_items']}</p>
        </div>
        <div class="summary-card">
            <h3>総過剰項目数</h3>
            <p style="font-size: 2em; margin: 0; color: #6f42c1;">{item_metrics['overall']['unexpected_items']}</p>
        </div>
        <div class="summary-card">
            <h3>正規化スコア（全体）</h3>
            <p style="font-size: 2em; margin: 0; color: #007bff;">{( (item_metrics['overall']['correct_items'] - item_metrics['overall']['wrong_items'] - item_metrics['overall']['unexpected_items']) / (item_metrics['overall']['expected_items'] or 1) ):.3f}</p>
        </div>
    </div>
    
    <!-- 全体情報サマリー -->
    <div class="summary">
        <div class="summary-card">
            <h3>総テストケース数</h3>
            <p style="font-size: 2em; margin: 0; color: #007bff;">{timing_stats['overall']['test_case_count']}</p>
        </div>
        <div class="summary-card">
            <h3>総抽出項目数</h3>
            <p style="font-size: 2em; margin: 0; color: #28a745;">{timing_stats['overall']['total_extraction_count']}</p>
        </div>
        <div class="summary-card">
            <h3>総抽出時間</h3>
            <p style="font-size: 2em; margin: 0; color: #dc3545;">{timing_stats['overall']['total_extraction_time']:.3f}秒</p>
        </div>
        <div class="summary-card">
            <h3>平均抽出時間</h3>
            <p style="font-size: 2em; margin: 0; color: #6f42c1;">{timing_stats['overall']['avg_extraction_time']:.3f}秒</p>
        </div>
    </div>
"""
    
    # 実験別精度分析は削除（method/language/patternの軸別比較へ集約）

    # 追加: 項目数ベースの軸別比較（method / language / pattern）
    def render_group_table(title, data):
        rows = ""
        for key, v in data.items():
            rows += f"""
                <tr>
                    <td>{key}</td>
                    <td>{v['expected_items']}</td>
                    <td class="correct">{v['correct_items']}</td>
                    <td class="wrong">{v['wrong_items']}</td>
                    <td class="missing">{v['missing_items']}</td>
                    <td class="unexpected">{v['unexpected_items']}</td>
                    <td><strong>{v['normalized_score']:.3f}</strong></td>
                </tr>
            """
        return f"""
    <div class="section">
        <h3>📊 {title}</h3>
        <table class="metrics-table">
            <thead>
                <tr>
                    <th>グループ</th>
                    <th>期待項目数</th>
                    <th>正解項目数</th>
                    <th>誤り項目数</th>
                    <th>欠落項目数</th>
                    <th>過剰項目数</th>
                    <th>正規化スコア</th>
                </tr>
            </thead>
            <tbody>
                {rows}
            </tbody>
        </table>
    </div>
        """
    
    def add_analysis_section(title, data, analysis_type):
        """分析・考察セクションを生成"""
        if not data:
            return ""
        
        # データを正規化スコアでソート
        sorted_data = sorted(data.items(), key=lambda x: x[1]['normalized_score'], reverse=True)
        
        # 最良・最悪のパフォーマンスを特定
        best = sorted_data[0]
        worst = sorted_data[-1]
        
        # 分析内容を生成
        analysis_content = ""
        
        if analysis_type == "method":
            analysis_content = f"""
            <h4>🔍 抽出方法別パフォーマンス分析</h4>
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0;">
                <p><strong>最良パフォーマンス:</strong> {best[0]} (正規化スコア: {best[1]['normalized_score']:.3f})</p>
                <p><strong>最悪パフォーマンス:</strong> {worst[0]} (正規化スコア: {worst[1]['normalized_score']:.3f})</p>
                <p><strong>分析:</strong></p>
                <ul>
                    <li>正規化スコアの差: {best[1]['normalized_score'] - worst[1]['normalized_score']:.3f}</li>
                    <li>最も正解率が高い方法: {max(data.items(), key=lambda x: x[1]['correct_items'])[0]}</li>
                    <li>最も過剰抽出が少ない方法: {min(data.items(), key=lambda x: x[1]['unexpected_items'])[0]}</li>
                </ul>
            </div>
            """
        elif analysis_type == "language":
            analysis_content = f"""
            <h4>🌐 言語別パフォーマンス分析</h4>
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0;">
                <p><strong>最良パフォーマンス:</strong> {best[0]} (正規化スコア: {best[1]['normalized_score']:.3f})</p>
                <p><strong>最悪パフォーマンス:</strong> {worst[0]} (正規化スコア: {worst[1]['normalized_score']:.3f})</p>
                <p><strong>分析:</strong></p>
                <ul>
                    <li>言語間の正規化スコア差: {best[1]['normalized_score'] - worst[1]['normalized_score']:.3f}</li>
                    <li>日本語の特徴: 正解項目数 {data.get('ja', {}).get('correct_items', 0)}, 過剰項目数 {data.get('ja', {}).get('unexpected_items', 0)}</li>
                    <li>英語の特徴: 正解項目数 {data.get('en', {}).get('correct_items', 0)}, 過剰項目数 {data.get('en', {}).get('unexpected_items', 0)}</li>
                </ul>
            </div>
            """
        elif analysis_type == "pattern":
            analysis_content = f"""
            <h4>📋 パターン別パフォーマンス分析</h4>
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0;">
                <p><strong>最良パフォーマンス:</strong> {best[0]} (正規化スコア: {best[1]['normalized_score']:.3f})</p>
                <p><strong>最悪パフォーマンス:</strong> {worst[0]} (正規化スコア: {worst[1]['normalized_score']:.3f})</p>
                <p><strong>分析:</strong></p>
                <ul>
                    <li>パターン間の正規化スコア差: {best[1]['normalized_score'] - worst[1]['normalized_score']:.3f}</li>
                    <li>最も複雑なパターン: {max(data.items(), key=lambda x: x[1]['expected_items'])[0]} (期待項目数: {max(data.items(), key=lambda x: x[1]['expected_items'])[1]['expected_items']})</li>
                    <li>最もシンプルなパターン: {min(data.items(), key=lambda x: x[1]['expected_items'])[0]} (期待項目数: {min(data.items(), key=lambda x: x[1]['expected_items'])[1]['expected_items']})</li>
                </ul>
            </div>
            """
        
        return f"""
    <div class="section">
        <h3>🧠 {title}</h3>
        {analysis_content}
    </div>
        """
    
    def generate_summary_section(item_metrics, grouped_scores, timing_stats):
        """レポートのまとめセクションを生成"""
        # 全体統計を計算
        overall = item_metrics.get('overall', {})
        total_expected = overall.get('expected_items', 0)
        total_correct = overall.get('correct_items', 0)
        total_wrong = overall.get('wrong_items', 0)
        total_missing = overall.get('missing_items', 0)
        total_unexpected = overall.get('unexpected_items', 0)
        overall_score = (total_correct - total_wrong - total_unexpected) / (total_expected or 1)
        
        # 各軸の最良・最悪を特定
        method_best = max(grouped_scores['by_method'].items(), key=lambda x: x[1]['normalized_score']) if grouped_scores['by_method'] else ("N/A", {"normalized_score": 0})
        method_worst = min(grouped_scores['by_method'].items(), key=lambda x: x[1]['normalized_score']) if grouped_scores['by_method'] else ("N/A", {"normalized_score": 0})
        
        language_best = max(grouped_scores['by_language'].items(), key=lambda x: x[1]['normalized_score']) if grouped_scores['by_language'] else ("N/A", {"normalized_score": 0})
        language_worst = min(grouped_scores['by_language'].items(), key=lambda x: x[1]['normalized_score']) if grouped_scores['by_language'] else ("N/A", {"normalized_score": 0})
        
        pattern_best = max(grouped_scores['by_pattern'].items(), key=lambda x: x[1]['normalized_score']) if grouped_scores['by_pattern'] else ("N/A", {"normalized_score": 0})
        pattern_worst = min(grouped_scores['by_pattern'].items(), key=lambda x: x[1]['normalized_score']) if grouped_scores['by_pattern'] else ("N/A", {"normalized_score": 0})
        
        return f"""
    <div class="section">
        <h3>📊 総合分析・まとめ</h3>
        <div style="background: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h4>🎯 全体パフォーマンス概要</h4>
            <p><strong>全体正規化スコア:</strong> {overall_score:.3f}</p>
            <p><strong>総期待項目数:</strong> {total_expected} | <strong>正解項目数:</strong> {total_correct} | <strong>誤り項目数:</strong> {total_wrong} | <strong>欠落項目数:</strong> {total_missing} | <strong>過剰項目数:</strong> {total_unexpected}</p>
        </div>
        
        <div style="background: #f3e5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h4>🔍 主要な発見・傾向</h4>
            <h5>1. 抽出方法別の特徴</h5>
            <ul>
                <li><strong>最良:</strong> {method_best[0]} (正規化スコア: {method_best[1]['normalized_score']:.3f})</li>
                <li><strong>最悪:</strong> {method_worst[0]} (正規化スコア: {method_worst[1]['normalized_score']:.3f})</li>
                <li><strong>性能差:</strong> {method_best[1]['normalized_score'] - method_worst[1]['normalized_score']:.3f}</li>
            </ul>
            
            <h5>2. 言語別の特徴</h5>
            <ul>
                <li><strong>最良:</strong> {language_best[0]} (正規化スコア: {language_best[1]['normalized_score']:.3f})</li>
                <li><strong>最悪:</strong> {language_worst[0]} (正規化スコア: {language_worst[1]['normalized_score']:.3f})</li>
                <li><strong>言語間差:</strong> {language_best[1]['normalized_score'] - language_worst[1]['normalized_score']:.3f}</li>
            </ul>
            
            <h5>3. パターン別の特徴</h5>
            <ul>
                <li><strong>最良:</strong> {pattern_best[0]} (正規化スコア: {pattern_best[1]['normalized_score']:.3f})</li>
                <li><strong>最悪:</strong> {pattern_worst[0]} (正規化スコア: {pattern_worst[1]['normalized_score']:.3f})</li>
                <li><strong>パターン間差:</strong> {pattern_best[1]['normalized_score'] - pattern_worst[1]['normalized_score']:.3f}</li>
            </ul>
        </div>
        
        <div style="background: #fff3e0; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h4>💡 仮説・推奨事項</h4>
            <h5>1. 抽出方法の最適化</h5>
            <ul>
                <li>{method_best[0]}が最も高い性能を示しているため、この方法の特性を他の方法に適用することを検討</li>
                <li>{method_worst[0]}の性能改善のため、プロンプト設計やパラメータ調整を検討</li>
            </ul>
            
            <h5>2. 言語対応の改善</h5>
            <ul>
                <li>言語間の性能差を縮小するため、言語固有の最適化を検討</li>
                <li>低性能言語のプロンプト設計や前処理の改善を検討</li>
            </ul>
            
            <h5>3. パターン別の最適化</h5>
            <ul>
                <li>{pattern_worst[0]}パターンの複雑さを分析し、段階的な学習アプローチを検討</li>
                <li>高性能パターンの成功要因を他のパターンに適用</li>
            </ul>
            
            <h5>4. 全体的な改善提案</h5>
            <ul>
                <li>過剰抽出率の削減: 現在{total_unexpected}項目の過剰抽出を削減</li>
                <li>欠落率の削減: 現在{total_missing}項目の欠落を削減</li>
                <li>正解率の向上: 現在{total_correct}/{total_expected} ({total_correct/(total_expected or 1)*100:.1f}%)の正解率を向上</li>
            </ul>
        </div>
        
        <div style="background: #e8f5e8; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h4>📈 今後の検討事項</h4>
            <ul>
                <li><strong>データ拡張:</strong> 不足しているパターン（CreditCard, PasswordManager, VoiceRecognition）のデータ追加</li>
                <li><strong>プロンプト最適化:</strong> 各抽出方法・言語・パターンに特化したプロンプト設計</li>
                <li><strong>パラメータ調整:</strong> 温度設定、最大トークン数等の最適化</li>
                <li><strong>評価指標の拡張:</strong> 抽出時間、コスト効率等の追加評価</li>
                <li><strong>継続的改善:</strong> 定期的なベンチマーク実行と性能追跡</li>
            </ul>
        </div>
    </div>
        """

    html_content += render_group_table("抽出方法別（yaml / generable / json）", grouped_scores['by_method'])
    html_content += add_analysis_section("抽出方法別分析", grouped_scores['by_method'], "method")
    
    html_content += render_group_table("言語別（en / ja）", grouped_scores['by_language'])
    html_content += add_analysis_section("言語別分析", grouped_scores['by_language'], "language")
    
    html_content += render_group_table("パターン別（Contract / Chat / CreditCard / PasswordManager / VoiceRecognition）", grouped_scores['by_pattern'])
    html_content += add_analysis_section("パターン別分析", grouped_scores['by_pattern'], "pattern")
    
    # 率ベースのパターン別精度表は削除（項目数ベース＋正規化スコアに統一）
    
    # フィールド別の詳細分析（4率の合計=1.0）
    html_content += """
    <div class="section">
        <h3>🏷️ フィールド別精度分析</h3>
        <table class="metrics-table">
            <thead>
                <tr>
                    <th>フィールド</th>
                    <th>正解率</th>
                    <th>誤り率</th>
                    <th>欠落率</th>
                    <th>過剰抽出率</th>
                </tr>
            </thead>
            <tbody>
"""
    
    for field, data in rates['by_field'].items():
        html_content += f"""
                <tr>
                    <td>{field}</td>
                    <td class="correct">{data['correct_rate']:.1%}</td>
                    <td class="wrong">{data['wrong_rate']:.1%}</td>
                    <td class="missing">{data['missing_rate']:.1%}</td>
                    <td class="unexpected">{data['unexpected_rate']:.1%}</td>
                </tr>
"""
    
    html_content += """
            </tbody>
        </table>
    </div>
"""
    
    # 抽出時間の統計セクションを追加
    if timing_stats and timing_stats['overall']['extraction_times']:
        html_content += """
    <div class="section">
        <h3>⏱️ 抽出時間統計</h3>
        <div class="summary">
            <div class="summary-card">
                <h3>平均抽出時間</h3>
                <p style="font-size: 2em; margin: 0; color: #007bff;">{:.3f}秒</p>
            </div>
            <div class="summary-card">
                <h3>最小抽出時間</h3>
                <p style="font-size: 2em; margin: 0; color: #28a745;">{:.3f}秒</p>
            </div>
            <div class="summary-card">
                <h3>最大抽出時間</h3>
                <p style="font-size: 2em; margin: 0; color: #dc3545;">{:.3f}秒</p>
            </div>
            <div class="summary-card">
                <h3>総抽出時間</h3>
                <p style="font-size: 2em; margin: 0; color: #6f42c1;">{:.3f}秒</p>
            </div>
        </div>
        
        <h4>実験別抽出時間</h4>
        <table class="metrics-table">
            <thead>
                <tr>
                    <th>実験</th>
                    <th>抽出方法</th>
                    <th>言語</th>
                    <th>平均時間</th>
                    <th>最小時間</th>
                    <th>最大時間</th>
                    <th>総時間</th>
                    <th>回数</th>
                </tr>
            </thead>
            <tbody>
""".format(
            timing_stats['overall']['avg_extraction_time'],
            timing_stats['overall']['min_extraction_time'],
            timing_stats['overall']['max_extraction_time'],
            timing_stats['overall']['total_extraction_time']
        )
        
        for experiment, data in timing_stats['by_experiment'].items():
            if data['extraction_times']:
                html_content += f"""
                <tr>
                    <td>{experiment}</td>
                    <td>{data['method']}</td>
                    <td>{data['language']}</td>
                    <td>{data['avg_extraction_time']:.3f}秒</td>
                    <td>{data['min_extraction_time']:.3f}秒</td>
                    <td>{data['max_extraction_time']:.3f}秒</td>
                    <td>{data['total_extraction_time']:.3f}秒</td>
                    <td>{len(data['extraction_times'])}回</td>
                </tr>
"""
        
        html_content += """
            </tbody>
        </table>
    </div>
"""
    
    # レベル別の率ベース表は削除（下の項目数ベースのレベル別表を掲載）
    
    # パターン・レベル別の率ベース表は削除（項目数ベース＋正規化スコアに統一）
    
    # パターン・レベル別抽出時間統計セクションを追加
    if timing_stats and 'by_pattern_level' in timing_stats and timing_stats['by_pattern_level']:
        html_content += """
    <div class="section">
        <h3>⏱️ パターン・レベル別抽出時間統計</h3>
        <table class="metrics-table">
            <thead>
                <tr>
                    <th>パターン</th>
                    <th>レベル</th>
                    <th>平均時間</th>
                    <th>最小時間</th>
                    <th>最大時間</th>
                    <th>総時間</th>
                    <th>テストケース数</th>
                </tr>
            </thead>
            <tbody>
"""
        
        for pattern, level_data in timing_stats['by_pattern_level'].items():
            for level, data in level_data.items():
                if data['extraction_times']:
                    html_content += f"""
                <tr>
                    <td>{pattern}</td>
                    <td>Level {level}</td>
                    <td>{data['avg_extraction_time']:.3f}秒</td>
                    <td>{data['min_extraction_time']:.3f}秒</td>
                    <td>{data['max_extraction_time']:.3f}秒</td>
                    <td>{data['total_extraction_time']:.3f}秒</td>
                    <td>{data['test_case_count']}</td>
                </tr>
"""
        
        html_content += """
            </tbody>
        </table>
    </div>
"""
    
    # 項目数ベースのメトリクスセクションを追加
    if item_metrics and 'by_pattern_level' in item_metrics and item_metrics['by_pattern_level']:
        html_content += """
    <div class="section">
        <h3>📊 項目数ベース分析（パターン・レベル別）</h3>
        <table class="metrics-table">
            <thead>
                <tr>
                    <th>パターン</th>
                    <th>レベル</th>
                    <th>期待項目数</th>
                    <th>正解項目数</th>
                    <th>誤り項目数</th>
                    <th>欠落項目数</th>
                    <th>過剰項目数</th>
                    <th>テストケース数</th>
                    <th>正規化スコア</th>
                </tr>
            </thead>
            <tbody>
"""
        
        for pattern, level_data in item_metrics['by_pattern_level'].items():
            for level, data in level_data.items():
                # 正規化スコアを計算
                expected = data['expected_items'] or 1
                normalized_score = (data['correct_items'] - data['wrong_items'] - data['unexpected_items']) / expected
                
                html_content += f"""
                <tr>
                    <td>{pattern}</td>
                    <td>Level {level}</td>
                    <td>{data['expected_items']}</td>
                    <td class="correct">{data['correct_items']}</td>
                    <td class="wrong">{data['wrong_items']}</td>
                    <td class="missing">{data['missing_items']}</td>
                    <td class="unexpected">{data['unexpected_items']}</td>
                    <td>{data['test_cases']}</td>
                    <td style="color: #007bff; font-weight: bold;">{normalized_score:.3f}</td>
                </tr>
"""
        
        html_content += """
            </tbody>
        </table>
    </div>
"""
    
    # レベル別項目数分析セクションを追加
    if item_metrics and 'by_level' in item_metrics and item_metrics['by_level']:
        html_content += """
    <div class="section">
        <h3>📊 項目数ベース分析（レベル別）</h3>
        <table class="metrics-table">
            <thead>
                <tr>
                    <th>レベル</th>
                    <th>期待項目数</th>
                    <th>正解項目数</th>
                    <th>誤り項目数</th>
                    <th>欠落項目数</th>
                    <th>過剰項目数</th>
                    <th>テストケース数</th>
                    <th>正規化スコア</th>
                </tr>
            </thead>
            <tbody>
"""
        
        for level, data in item_metrics['by_level'].items():
            # 正規化スコアを計算
            expected = data['expected_items'] or 1
            normalized_score = (data['correct_items'] - data['wrong_items'] - data['unexpected_items']) / expected
            
            html_content += f"""
                <tr>
                    <td>Level {level}</td>
                    <td>{data['expected_items']}</td>
                    <td class="correct">{data['correct_items']}</td>
                    <td class="wrong">{data['wrong_items']}</td>
                    <td class="missing">{data['missing_items']}</td>
                    <td class="unexpected">{data['unexpected_items']}</td>
                    <td>{data['test_cases']}</td>
                    <td style="color: #007bff; font-weight: bold;">{normalized_score:.3f}</td>
                </tr>
"""
        
        html_content += """
            </tbody>
        </table>
    </div>
"""
    
    # グラフセクションは削除（率ベースの視覚化を撤廃）
    
    # メトリクス定義セクションを追加
    html_content += """
    <div class="section">
        <h3>📋 メトリクス定義</h3>
        <div style="background: #f8f9fa; padding: 20px; border-radius: 8px;">
            <h4>精度メトリクス（項目数ベース）</h4>
            <ul>
                <li><strong>期待項目数 (Expected Items)</strong>: 評価対象フィールド総数</li>
                <li><strong>正解項目数 (Correct Items)</strong>: 期待項目のうち正しい値を抽出できた数</li>
                <li><strong>誤り項目数 (Wrong Items)</strong>: 期待項目のうち誤った値を抽出した数</li>
                <li><strong>欠落項目数 (Missing Items)</strong>: 期待項目のうち抽出に失敗した数</li>
                <li><strong>過剰項目数 (Unexpected Items)</strong>: 期待されない項目を抽出した数</li>
                <li><strong>正規化スコア (Normalized Score)</strong>: (正解項目数 − 誤り項目数 − 過剰項目数) / 期待項目数</li>
            </ul>
            
            <h4>抽出時間メトリクス</h4>
            <ul>
                <li><strong>平均抽出時間</strong>: 全テストケースの抽出時間の平均値</li>
                <li><strong>最小抽出時間</strong>: 全テストケースの抽出時間の最小値</li>
                <li><strong>最大抽出時間</strong>: 全テストケースの抽出時間の最大値</li>
                <li><strong>総抽出時間</strong>: 全テストケースの抽出時間の合計</li>
            </ul>
        </div>
    </div>
"""
    
    # まとめセクションを追加
    html_content += generate_summary_section(item_metrics, grouped_scores, timing_stats)
    
    html_content += """
    <div class="header">
        <h2>📊 分析完了</h2>
        <p>@ai[2024-12-19 18:30] FoundationModels 精度分析レポート</p>
        <p><strong>注意:</strong> pending項目はAIによる詳細検証が必要です。</p>
    </div>
    
    <script>
        // グラフデータの準備
        const experimentData = {
            labels: [],
            correct: [],
            wrong: [],
            missing: [],
            unexpected: []
        };
        
        const timingData = {
            labels: [],
            avgTime: [],
            minTime: [],
            maxTime: []
        };
        
        const levelData = {
            labels: [],
            correct: [],
            wrong: [],
            missing: [],
            unexpected: []
        };
        
        const patternData = {
            labels: [],
            correct: [],
            wrong: [],
            missing: [],
            unexpected: []
        };
        
        // 項目数ベースのグラフデータ
        const itemLevelData = {
            labels: [],
            expected: [],
            correct: [],
            wrong: [],
            missing: [],
            unexpected: []
        };
        
        const itemPatternLevelData = {
            labels: [],
            expected: [],
            correct: [],
            wrong: [],
            missing: [],
            unexpected: []
        };
        
        // データを設定
"""
    
    # 実験別データを追加
    if 'by_experiment' in rates and rates['by_experiment']:
        for experiment, data in rates['by_experiment'].items():
            html_content += f"""
        experimentData.labels.push('{experiment}');
        experimentData.correct.push({data['correct_rate']:.3f});
        experimentData.wrong.push({data['wrong_rate']:.3f});
        experimentData.missing.push({data['missing_rate']:.3f});
        experimentData.unexpected.push({data['unexpected_rate']:.3f});
"""
    
    # 抽出時間データを追加
    if timing_stats and timing_stats['by_experiment']:
        for experiment, data in timing_stats['by_experiment'].items():
            if data['extraction_times']:
                html_content += f"""
        timingData.labels.push('{experiment}');
        timingData.avgTime.push({data['avg_extraction_time']:.3f});
        timingData.minTime.push({data['min_extraction_time']:.3f});
        timingData.maxTime.push({data['max_extraction_time']:.3f});
"""
    
    # レベル別データを追加
    if 'by_level' in rates and rates['by_level']:
        for level, data in rates['by_level'].items():
            html_content += f"""
        levelData.labels.push('Level {level}');
        levelData.correct.push({data['correct_rate']:.3f});
        levelData.wrong.push({data['wrong_rate']:.3f});
        levelData.missing.push({data['missing_rate']:.3f});
        levelData.unexpected.push({data['unexpected_rate']:.3f});
"""
    
    # パターン別データを追加
    if 'by_pattern' in rates and rates['by_pattern']:
        for pattern, data in rates['by_pattern'].items():
            html_content += f"""
        patternData.labels.push('{pattern}');
        patternData.correct.push({data['correct_rate']:.3f});
        patternData.wrong.push({data['wrong_rate']:.3f});
        patternData.missing.push({data['missing_rate']:.3f});
        patternData.unexpected.push({data['unexpected_rate']:.3f});
"""
    
    # 項目数ベースのレベル別データを追加
    if item_metrics and 'by_level' in item_metrics and item_metrics['by_level']:
        for level, data in item_metrics['by_level'].items():
            html_content += f"""
        itemLevelData.labels.push('Level {level}');
        itemLevelData.expected.push({data['expected_items']});
        itemLevelData.correct.push({data['correct_items']});
        itemLevelData.wrong.push({data['wrong_items']});
        itemLevelData.missing.push({data['missing_items']});
        itemLevelData.unexpected.push({data['unexpected_items']});
"""
    
    # 項目数ベースのパターン・レベル別データを追加
    if item_metrics and 'by_pattern_level' in item_metrics and item_metrics['by_pattern_level']:
        for pattern, level_data in item_metrics['by_pattern_level'].items():
            for level, data in level_data.items():
                html_content += f"""
        itemPatternLevelData.labels.push('{pattern} L{level}');
        itemPatternLevelData.expected.push({data['expected_items']});
        itemPatternLevelData.correct.push({data['correct_items']});
        itemPatternLevelData.wrong.push({data['wrong_items']});
        itemPatternLevelData.missing.push({data['missing_items']});
        itemPatternLevelData.unexpected.push({data['unexpected_items']});
"""
    
    html_content += """
        
        // グラフの描画
        const chartOptions = {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    max: 1
                }
            }
        };
        
        // 実験別精度比較グラフ
        new Chart(document.getElementById('accuracyChart'), {
            type: 'bar',
            data: {
                labels: experimentData.labels,
                datasets: [
                    {
                        label: '正解率',
                        data: experimentData.correct,
                        backgroundColor: 'rgba(40, 167, 69, 0.7)',
                        borderColor: 'rgba(40, 167, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '誤り率',
                        data: experimentData.wrong,
                        backgroundColor: 'rgba(220, 53, 69, 0.7)',
                        borderColor: 'rgba(220, 53, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '欠落率',
                        data: experimentData.missing,
                        backgroundColor: 'rgba(255, 193, 7, 0.7)',
                        borderColor: 'rgba(255, 193, 7, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '過剰抽出率',
                        data: experimentData.unexpected,
                        backgroundColor: 'rgba(111, 66, 193, 0.7)',
                        borderColor: 'rgba(111, 66, 193, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: chartOptions
        });
        
        // 抽出時間比較グラフ
        new Chart(document.getElementById('timingChart'), {
            type: 'bar',
            data: {
                labels: timingData.labels,
                datasets: [
                    {
                        label: '平均時間',
                        data: timingData.avgTime,
                        backgroundColor: 'rgba(0, 123, 255, 0.7)',
                        borderColor: 'rgba(0, 123, 255, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '最小時間',
                        data: timingData.minTime,
                        backgroundColor: 'rgba(40, 167, 69, 0.7)',
                        borderColor: 'rgba(40, 167, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '最大時間',
                        data: timingData.maxTime,
                        backgroundColor: 'rgba(220, 53, 69, 0.7)',
                        borderColor: 'rgba(220, 53, 69, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
        
        // レベル別精度分析グラフ
        new Chart(document.getElementById('levelChart'), {
            type: 'bar',
            data: {
                labels: levelData.labels,
                datasets: [
                    {
                        label: '正解率',
                        data: levelData.correct,
                        backgroundColor: 'rgba(40, 167, 69, 0.7)',
                        borderColor: 'rgba(40, 167, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '誤り率',
                        data: levelData.wrong,
                        backgroundColor: 'rgba(220, 53, 69, 0.7)',
                        borderColor: 'rgba(220, 53, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '欠落率',
                        data: levelData.missing,
                        backgroundColor: 'rgba(255, 193, 7, 0.7)',
                        borderColor: 'rgba(255, 193, 7, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '過剰抽出率',
                        data: levelData.unexpected,
                        backgroundColor: 'rgba(111, 66, 193, 0.7)',
                        borderColor: 'rgba(111, 66, 193, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: chartOptions
        });
        
        // パターン別精度分析グラフ
        new Chart(document.getElementById('patternChart'), {
            type: 'bar',
            data: {
                labels: patternData.labels,
                datasets: [
                    {
                        label: '正解率',
                        data: patternData.correct,
                        backgroundColor: 'rgba(40, 167, 69, 0.7)',
                        borderColor: 'rgba(40, 167, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '誤り率',
                        data: patternData.wrong,
                        backgroundColor: 'rgba(220, 53, 69, 0.7)',
                        borderColor: 'rgba(220, 53, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '欠落率',
                        data: patternData.missing,
                        backgroundColor: 'rgba(255, 193, 7, 0.7)',
                        borderColor: 'rgba(255, 193, 7, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '過剰抽出率',
                        data: patternData.unexpected,
                        backgroundColor: 'rgba(111, 66, 193, 0.7)',
                        borderColor: 'rgba(111, 66, 193, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: chartOptions
        });
        
        // 項目数ベースのレベル別グラフ
        new Chart(document.getElementById('itemLevelChart'), {
            type: 'bar',
            data: {
                labels: itemLevelData.labels,
                datasets: [
                    {
                        label: '期待項目数',
                        data: itemLevelData.expected,
                        backgroundColor: 'rgba(0, 123, 255, 0.7)',
                        borderColor: 'rgba(0, 123, 255, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '正解項目数',
                        data: itemLevelData.correct,
                        backgroundColor: 'rgba(40, 167, 69, 0.7)',
                        borderColor: 'rgba(40, 167, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '誤り項目数',
                        data: itemLevelData.wrong,
                        backgroundColor: 'rgba(220, 53, 69, 0.7)',
                        borderColor: 'rgba(220, 53, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '欠落項目数',
                        data: itemLevelData.missing,
                        backgroundColor: 'rgba(255, 193, 7, 0.7)',
                        borderColor: 'rgba(255, 193, 7, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '過剰項目数',
                        data: itemLevelData.unexpected,
                        backgroundColor: 'rgba(111, 66, 193, 0.7)',
                        borderColor: 'rgba(111, 66, 193, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
        
        // 項目数ベースのパターン・レベル別グラフ
        new Chart(document.getElementById('itemPatternLevelChart'), {
            type: 'bar',
            data: {
                labels: itemPatternLevelData.labels,
                datasets: [
                    {
                        label: '期待項目数',
                        data: itemPatternLevelData.expected,
                        backgroundColor: 'rgba(0, 123, 255, 0.7)',
                        borderColor: 'rgba(0, 123, 255, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '正解項目数',
                        data: itemPatternLevelData.correct,
                        backgroundColor: 'rgba(40, 167, 69, 0.7)',
                        borderColor: 'rgba(40, 167, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '誤り項目数',
                        data: itemPatternLevelData.wrong,
                        backgroundColor: 'rgba(220, 53, 69, 0.7)',
                        borderColor: 'rgba(220, 53, 69, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '欠落項目数',
                        data: itemPatternLevelData.missing,
                        backgroundColor: 'rgba(255, 193, 7, 0.7)',
                        borderColor: 'rgba(255, 193, 7, 1)',
                        borderWidth: 1
                    },
                    {
                        label: '過剰項目数',
                        data: itemPatternLevelData.unexpected,
                        backgroundColor: 'rgba(111, 66, 193, 0.7)',
                        borderColor: 'rgba(111, 66, 193, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    </script>
</body>
</html>
"""
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html_content)

def main():
    if len(sys.argv) != 2:
        print("使用方法: python3 generate_combined_report.py <ログディレクトリ>")
        sys.exit(1)
    
    log_dir = sys.argv[1]
    # レポートもログディレクトリに出力
    report_dir = log_dir
    
    # ログファイルを検索（ディレクトリ構造対応）
    log_files = []
    
    # 従来の形式のログファイル
    log_files.extend(list(Path(log_dir).glob("format_experiment_*.log")))
    
    # 新しいディレクトリ構造のJSONファイル
    json_files = list(Path(log_dir).glob("**/*.json"))
    log_files.extend(json_files)
    
    if not log_files:
        print(f"エラー: ログディレクトリ {log_dir} にログファイルが見つかりません")
        sys.exit(1)
    
    print(f"📁 ログファイル数: {len(log_files)}")
    
    # 各ログファイルを解析
    all_results = []
    for log_file in log_files:
        print(f"🔍 解析中: {log_file.name}")
        result = parse_log_file(str(log_file))
        all_results.append(result)
    
    # 精度メトリクスを計算
    metrics = calculate_accuracy_metrics(all_results)
    rates = calculate_rates(metrics)
    
    # 抽出時間の統計を計算
    timing_stats = calculate_timing_stats(all_results)
    
    # 詳細な統計情報を表示
    print(f"\n📊 精度分析結果:")
    if 'overall' in rates:
        print(f"  総フィールド数: {sum(metrics['overall'].values())}")
        print(f"  正解率: {rates['overall']['correct_rate']:.1%}")
        print(f"  誤り率: {rates['overall']['wrong_rate']:.1%}")
        print(f"  欠落率: {rates['overall']['missing_rate']:.1%}")
        print(f"  過剰抽出率: {rates['overall']['unexpected_rate']:.1%}")
        print(f"  Precision: {rates['overall']['precision']:.3f}")
        print(f"  Recall: {rates['overall']['recall']:.3f}")
    else:
        print("  データが不足しています。JSONログの抽出に問題があります。")
    
    # 抽出時間の統計を表示
    print(f"\n⏱️  抽出時間統計:")
    if timing_stats['overall']['extraction_times']:
        print(f"  平均抽出時間: {timing_stats['overall']['avg_extraction_time']:.3f}秒")
        print(f"  最小抽出時間: {timing_stats['overall']['min_extraction_time']:.3f}秒")
        print(f"  最大抽出時間: {timing_stats['overall']['max_extraction_time']:.3f}秒")
        print(f"  総抽出時間: {timing_stats['overall']['total_extraction_time']:.3f}秒")
        print(f"  抽出回数: {len(timing_stats['overall']['extraction_times'])}回")
    else:
        print("  抽出時間データがありません。")
    
    # 項目数ベースのメトリクスを計算
    item_metrics = calculate_item_based_metrics(all_results)
    
    # HTMLレポートを生成
    output_path = os.path.join(report_dir, "parallel_format_experiment_report.html")
    generate_html_report(all_results, output_path, rates, timing_stats, item_metrics)
    
    print(f"✅ 統合レポートを生成しました: {output_path}")
    
    # JSON形式の詳細データも保存
    json_output_path = os.path.join(report_dir, "detailed_metrics.json")
    detailed_data = {
        'metrics': dict(metrics),
        'rates': rates,
        'timestamp': datetime.now().isoformat()
    }
    
    with open(json_output_path, 'w', encoding='utf-8') as f:
        json.dump(detailed_data, f, ensure_ascii=False, indent=2)
    
    print(f"✅ 詳細メトリクスを保存しました: {json_output_path}")

if __name__ == "__main__":
    main()
