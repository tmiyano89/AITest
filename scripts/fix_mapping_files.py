#!/usr/bin/env python3
"""
マッピングファイル自動修正スクリプト

目的: 検証スクリプトで発見されたマッピングファイルのエラーを自動修正
背景: 構造体のフィールド名とマッピングルールのキーが一致しない問題を修正
意図: 全マッピングファイルを実際の構造体定義に合わせて修正
"""

import json
import sys
from pathlib import Path
from typing import Dict

# カラー出力用のANSIコード
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def fix_mapping_file(mapping_file_path: Path, fix_rules: Dict[str, Dict[str, str]]) -> bool:
    """
    マッピングファイルを修正

    Args:
        mapping_file_path: マッピングファイルのパス
        fix_rules: 修正ルール（旧フィールド名 -> 新フィールド名）

    Returns:
        修正が必要だった場合True
    """
    with open(mapping_file_path, 'r', encoding='utf-8') as f:
        mapping_data = json.load(f)

    subcategory = mapping_data.get('subCategory', '')

    if subcategory not in fix_rules:
        return False

    rules = fix_rules[subcategory]
    modified = False

    # directMappingを修正
    if 'directMapping' in mapping_data:
        new_direct_mapping = {}
        for old_key, value in mapping_data['directMapping'].items():
            if old_key in rules:
                new_key = rules[old_key]
                print(f"    🔧 directMapping: '{old_key}' -> '{new_key}'")
                new_direct_mapping[new_key] = value
                modified = True
            else:
                new_direct_mapping[old_key] = value
        mapping_data['directMapping'] = new_direct_mapping

    # noteAppendMappingを修正
    if 'noteAppendMapping' in mapping_data:
        new_note_append_mapping = {}
        for old_key, value in mapping_data['noteAppendMapping'].items():
            if old_key in rules:
                new_key = rules[old_key]
                print(f"    🔧 noteAppendMapping: '{old_key}' -> '{new_key}'")
                new_note_append_mapping[new_key] = value
                modified = True
            else:
                new_note_append_mapping[old_key] = value
        mapping_data['noteAppendMapping'] = new_note_append_mapping

    if modified:
        # ファイルを保存（フォーマットを保持）
        with open(mapping_file_path, 'w', encoding='utf-8') as f:
            json.dump(mapping_data, f, indent=2, ensure_ascii=False)
            f.write('\n')  # 最後に改行を追加

    return modified

def main():
    # プロジェクトルートディレクトリ
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    mappings_dir = project_root / "Sources/AITest/Mappings"

    if not mappings_dir.exists():
        print(f"{Colors.RED}❌ マッピングディレクトリが見つかりません: {mappings_dir}{Colors.END}")
        sys.exit(1)

    # 修正ルール: サブカテゴリ -> {旧フィールド名: 新フィールド名}
    fix_rules = {
        # Digital
        'digitalAI': {
            'username': 'userID',
            'loginURL': 'url',
            'platformName': 'serviceName'
        },
        'digitalApps': {
            'username': 'userID'
        },
        'digitalShopping': {
            'username': 'userID',
            'loginURL': 'url'
        },
        'digitalSocial': {
            'siteName': 'platformName'
        },
        'digitalSubscription': {
            'username': 'userID',
            'loginURL': 'url'
        },

        # Financial
        'financialCrypto': {
            'username': 'userID',
            'loginURL': 'url'
        },
        'financialPayment': {
            'username': 'userID'
        },

        # Infrastructure
        'infraGovernment': {
            'username': 'userID',
            'loginURL': 'url'
        },

        # Personal
        'personalContacts': {
            'description': 'note'  # descriptionフィールドは存在しないのでnoteに統合
        },

        # Work
        'workCommunication': {
            'username': 'userID',
            'loginURL': 'url'
        },
        'workDevelopment': {
            'password': 'apiKey'  # passwordフィールドは存在しないのでapiKeyにマップ
        },
        'workOther': {
            'username': 'userID'
        },
        'workSaaS': {
            'username': 'userID',
            'loginURL': 'url'
        },
        'workServer': {
            'username': 'userID',
            'serverAddress': 'host'
        }
    }

    print(f"{Colors.BLUE}🔧 マッピングファイルを修正中...{Colors.END}\n")
    print("=" * 80)

    modified_count = 0

    for subcategory, rules in fix_rules.items():
        mapping_file = mappings_dir / f"{subcategory}_mapping.json"

        if not mapping_file.exists():
            print(f"{Colors.RED}❌ ファイルが見つかりません: {mapping_file}{Colors.END}")
            continue

        print(f"{Colors.YELLOW}📝 {subcategory}{Colors.END}")
        modified = fix_mapping_file(mapping_file, fix_rules)

        if modified:
            print(f"  {Colors.GREEN}✅ 修正完了{Colors.END}")
            modified_count += 1
        else:
            print(f"  ℹ️  修正不要")

        print()

    print("=" * 80)
    print(f"\n{Colors.BOLD}📊 修正結果{Colors.END}")
    print(f"  修正したファイル: {modified_count}個")

    if modified_count > 0:
        print(f"\n{Colors.GREEN}{Colors.BOLD}✅ マッピングファイルの修正が完了しました！{Colors.END}")
        print(f"\n{Colors.YELLOW}💡 次のステップ:{Colors.END}")
        print(f"  1. python3 scripts/validate_mapping_files.py を実行して検証")
        print(f"  2. swift run AITestApp --method generable --testcase chat --language ja --mode two-steps --levels 1")
        print(f"     でテストを実行")
    else:
        print(f"\n{Colors.BLUE}ℹ️  修正が必要なファイルはありませんでした{Colors.END}")

if __name__ == '__main__':
    main()
