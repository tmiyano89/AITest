#!/usr/bin/env python3
"""
マッピングファイル検証スクリプト

目的: 各サブカテゴリのマッピングファイルが、実際の構造体定義と一致するかを検証
背景: マッピングルールのソースフィールド名が構造体のフィールド名と一致しない場合、
      抽出された情報が正しくAccountInfoに変換されない
意図: 全25個のマッピングファイルを自動検証し、不一致をレポート
"""

import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

# カラー出力用のANSIコード
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def parse_struct_fields(swift_file_path: Path) -> Dict[str, Set[str]]:
    """
    SubCategoryExtractionStructs.swiftをパースして各構造体のフィールド名を抽出

    Returns:
        Dict[構造体名, Set[フィールド名]]
    """
    print(f"{Colors.BLUE}📖 構造体定義を解析中...{Colors.END}")

    with open(swift_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 構造体定義を抽出するパターン
    # public struct XXXInfo: ... { ... }
    struct_pattern = r'public struct (\w+Info):\s*[^{]+\{(.*?)(?=\npublic struct|\nclass|\nprotocol|\n@available|\Z)'

    structs = {}

    for match in re.finditer(struct_pattern, content, re.DOTALL):
        struct_name = match.group(1)
        struct_body = match.group(2)

        # フィールド定義を抽出: public var fieldName: Type?
        field_pattern = r'public var (\w+):\s*[^=\n]+'
        fields = set(re.findall(field_pattern, struct_body))

        structs[struct_name] = fields
        print(f"  ✅ {struct_name}: {len(fields)}フィールド")

    print(f"{Colors.GREEN}✅ {len(structs)}個の構造体を解析完了{Colors.END}\n")
    return structs

def get_struct_name_from_subcategory(subcategory: str) -> str:
    """
    サブカテゴリ名から構造体名を推測

    例: workServer -> WorkServerInfo
    """
    # キャメルケースに変換
    parts = subcategory.split('_')
    if len(parts) == 1:
        # 既にキャメルケースの場合
        # 最初の小文字部分を大文字に
        camel_case = subcategory[0].upper() + subcategory[1:]
    else:
        camel_case = ''.join(part.capitalize() for part in parts)

    return f"{camel_case}Info"

def validate_mapping_file(
    mapping_file_path: Path,
    struct_fields: Dict[str, Set[str]]
) -> Tuple[bool, List[str]]:
    """
    マッピングファイルを検証

    Returns:
        (検証成功か, エラーメッセージのリスト)
    """
    with open(mapping_file_path, 'r', encoding='utf-8') as f:
        mapping_data = json.load(f)

    subcategory = mapping_data.get('subCategory', '')
    struct_name = get_struct_name_from_subcategory(subcategory)

    if struct_name not in struct_fields:
        return False, [f"構造体 {struct_name} が見つかりません"]

    expected_fields = struct_fields[struct_name]
    errors = []

    # directMappingのキー（ソースフィールド）をチェック
    direct_mapping = mapping_data.get('directMapping', {})
    for source_field in direct_mapping.keys():
        if source_field not in expected_fields:
            target_field = direct_mapping[source_field]
            errors.append(
                f"  ❌ directMapping: '{source_field}' -> '{target_field}' "
                f"(構造体に '{source_field}' フィールドが存在しません)"
            )

    # noteAppendMappingのキー（ソースフィールド）をチェック
    note_append_mapping = mapping_data.get('noteAppendMapping', {})
    for source_field in note_append_mapping.keys():
        if source_field not in expected_fields:
            label = note_append_mapping[source_field]
            errors.append(
                f"  ❌ noteAppendMapping: '{source_field}' -> '{label}' "
                f"(構造体に '{source_field}' フィールドが存在しません)"
            )

    # 使われていないフィールドを警告（オプショナル）
    used_fields = set(direct_mapping.keys()) | set(note_append_mapping.keys())
    unused_fields = expected_fields - used_fields - {'title', 'note'}  # title, noteは必須フィールド

    if unused_fields:
        errors.append(
            f"  ⚠️  未使用フィールド: {', '.join(sorted(unused_fields))}"
        )

    return len([e for e in errors if e.startswith('  ❌')]) == 0, errors

def main():
    # プロジェクトルートディレクトリ
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    # パス設定
    swift_file = project_root / "Sources/AITest/SubCategoryExtractionStructs.swift"
    mappings_dir = project_root / "Sources/AITest/Mappings"

    if not swift_file.exists():
        print(f"{Colors.RED}❌ 構造体定義ファイルが見つかりません: {swift_file}{Colors.END}")
        sys.exit(1)

    if not mappings_dir.exists():
        print(f"{Colors.RED}❌ マッピングディレクトリが見つかりません: {mappings_dir}{Colors.END}")
        sys.exit(1)

    # 構造体定義を解析
    struct_fields = parse_struct_fields(swift_file)

    # 全マッピングファイルを検証
    print(f"{Colors.BLUE}🔍 マッピングファイルを検証中...{Colors.END}\n")

    mapping_files = sorted(mappings_dir.glob("*_mapping.json"))

    if not mapping_files:
        print(f"{Colors.RED}❌ マッピングファイルが見つかりません{Colors.END}")
        sys.exit(1)

    print(f"検証対象: {len(mapping_files)}ファイル\n")
    print("=" * 80)

    all_valid = True
    results = []

    for mapping_file in mapping_files:
        subcategory_name = mapping_file.stem.replace('_mapping', '')
        valid, errors = validate_mapping_file(mapping_file, struct_fields)

        results.append((subcategory_name, valid, errors))

        if valid and not errors:
            print(f"{Colors.GREEN}✅ {subcategory_name}{Colors.END}")
        elif valid and errors:
            print(f"{Colors.YELLOW}⚠️  {subcategory_name}{Colors.END}")
            for error in errors:
                print(error)
        else:
            print(f"{Colors.RED}❌ {subcategory_name}{Colors.END}")
            for error in errors:
                print(error)
            all_valid = False

        print()

    print("=" * 80)

    # サマリー
    valid_count = sum(1 for _, valid, errors in results if valid and not any(e.startswith('  ❌') for e in errors))
    warning_count = sum(1 for _, valid, errors in results if valid and any(e.startswith('  ⚠️') for e in errors))
    error_count = sum(1 for _, valid, _ in results if not valid)

    print(f"\n{Colors.BOLD}📊 検証結果サマリー{Colors.END}")
    print(f"  {Colors.GREEN}✅ 正常: {valid_count}ファイル{Colors.END}")
    print(f"  {Colors.YELLOW}⚠️  警告: {warning_count}ファイル{Colors.END}")
    print(f"  {Colors.RED}❌ エラー: {error_count}ファイル{Colors.END}")

    if all_valid:
        print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 全てのマッピングファイルが正常です！{Colors.END}")
        sys.exit(0)
    else:
        print(f"\n{Colors.RED}{Colors.BOLD}❌ エラーのあるマッピングファイルがあります{Colors.END}")
        print(f"\n{Colors.YELLOW}💡 修正方法:{Colors.END}")
        print(f"  1. SubCategoryExtractionStructs.swiftで実際のフィールド名を確認")
        print(f"  2. マッピングファイルのdirectMapping/noteAppendMappingのキーを修正")
        print(f"  3. このスクリプトを再実行して検証")
        sys.exit(1)

if __name__ == '__main__':
    main()
