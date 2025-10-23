#!/usr/bin/env python3
"""
サブカテゴリ定義ファイル生成スクリプト

目的: 既存のmappingファイルと構造体定義から、25個のサブカテゴリ定義JSONを生成
背景: より柔軟で拡張性の高い設計への移行
意図: generable/json両方に対応した統一的な定義ファイルを作成
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

def parse_struct_fields(swift_file_path: Path) -> Dict[str, List[Tuple[str, str]]]:
    """
    SubCategoryExtractionStructs.swiftをパースして各構造体のフィールドと説明を抽出

    Returns:
        Dict[構造体名, List[(フィールド名, 説明)]]
    """
    print(f"{Colors.BLUE}📖 構造体定義を解析中...{Colors.END}")

    with open(swift_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 構造体定義を抽出するパターン
    struct_pattern = r'public struct (\w+Info):\s*[^{]+\{(.*?)(?=\npublic struct|\nclass|\nprotocol|\n@available|\Z)'

    structs = {}

    for match in re.finditer(struct_pattern, content, re.DOTALL):
        struct_name = match.group(1)
        struct_body = match.group(2)

        # フィールド定義と@Guide説明を抽出
        fields = []

        # @Guide(description: "説明") の次の行の public var fieldName: Type?
        guide_pattern = r'@Guide\(description:\s*"([^"]+)"[^)]*\)\s+public var (\w+):\s*([^=\n]+)'

        for guide_match in re.finditer(guide_pattern, struct_body):
            description = guide_match.group(1)
            field_name = guide_match.group(2)
            fields.append((field_name, description))

        structs[struct_name] = fields
        print(f"  ✅ {struct_name}: {len(fields)}フィールド")

    print(f"{Colors.GREEN}✅ {len(structs)}個の構造体を解析完了{Colors.END}\n")
    return structs

def parse_subcategory_info(content_info_file: Path) -> Dict[str, Dict]:
    """
    ContentInfo.swiftからサブカテゴリの情報を抽出

    Returns:
        Dict[サブカテゴリID, {displayName_ja, mainCategory}]
    """
    print(f"{Colors.BLUE}📖 サブカテゴリ情報を解析中...{Colors.END}")

    with open(content_info_file, 'r', encoding='utf-8') as f:
        content = f.read()

    subcategories = {}

    # SubCategory enum の displayName を抽出
    display_name_pattern = r'case \.(\w+):\s*return\s*"([^"]+)"'
    for match in re.finditer(display_name_pattern, content):
        subcategory_id = match.group(1)
        display_name_ja = match.group(2)
        subcategories[subcategory_id] = {"displayName_ja": display_name_ja}

    # mainCategory プロパティから親カテゴリを抽出
    main_category_pattern = r'case\s+([\w,\s]+):\s*return\s*\.(\w+)'
    for match in re.finditer(main_category_pattern, content):
        cases = [c.strip() for c in match.group(1).replace('.', '').split(',')]
        main_category = match.group(2)

        for case in cases:
            if case in subcategories:
                subcategories[case]["mainCategory"] = main_category

    print(f"{Colors.GREEN}✅ {len(subcategories)}個のサブカテゴリ情報を解析完了{Colors.END}\n")
    return subcategories

def get_struct_name_from_subcategory(subcategory: str) -> str:
    """サブカテゴリ名から構造体名を推測"""
    camel_case = subcategory[0].upper() + subcategory[1:]
    return f"{camel_case}Info"

def generate_extraction_prompt(
    subcategory_id: str,
    display_name_ja: str,
    fields: List[Tuple[str, str]],
    language: str
) -> str:
    """抽出用プロンプトを生成"""

    if language == "ja":
        prompt = f"""以下の文書から、{display_name_ja}に関するアカウント情報を抽出してください。
文書にない情報は抽出しないでください。

## 抽出する情報

以下の情報を可能な限り抽出してください：

"""
        for field_name, description in fields:
            prompt += f"- **{field_name}**: {description}\n"

        prompt += """
## 対象文書

{TEXT}

## 出力形式

JSON形式で以下のように出力してください。値がない場合はnullを設定してください。

```json
{
"""
        field_examples = []
        for field_name, _ in fields:
            # Int型の場合は数値、それ以外は文字列
            if 'port' in field_name.lower() or field_name.endswith('Fee'):
                field_examples.append(f'  "{field_name}": 数値またはnull')
            else:
                field_examples.append(f'  "{field_name}": "値" または null')

        prompt += ",\n".join(field_examples)
        prompt += "\n}\n```"

    else:  # English
        prompt = f"""Please extract account information related to {display_name_ja} from the following document.
Do not extract information that is not in the document.

## Information to Extract

Please extract the following information as much as possible:

"""
        for field_name, description in fields:
            prompt += f"- **{field_name}**: {description}\n"

        prompt += """
## Target Document

{TEXT}

## Output Format

Please output in JSON format as follows. Set null if the value is not available.

```json
{
"""
        field_examples = []
        for field_name, _ in fields:
            if 'port' in field_name.lower() or field_name.endswith('Fee'):
                field_examples.append(f'  "{field_name}": number or null')
            else:
                field_examples.append(f'  "{field_name}": "value" or null')

        prompt += ",\n".join(field_examples)
        prompt += "\n}\n```"

    return prompt

def generate_subcategory_definition(
    subcategory_id: str,
    subcategory_info: Dict,
    struct_fields: List[Tuple[str, str]],
    mapping_data: Dict
) -> Dict:
    """サブカテゴリ定義JSONを生成"""

    display_name_ja = subcategory_info.get("displayName_ja", subcategory_id)
    main_category = subcategory_info.get("mainCategory", "unknown")

    # 簡易的な英語名生成（改善の余地あり）
    display_name_en = display_name_ja  # 暫定

    # プロンプト生成
    prompt_ja = generate_extraction_prompt(subcategory_id, display_name_ja, struct_fields, "ja")
    prompt_en = generate_extraction_prompt(subcategory_id, display_name_ja, struct_fields, "en")

    definition = {
        "id": subcategory_id,
        "mainCategoryId": main_category,
        "name": {
            "ja": display_name_ja,
            "en": display_name_en
        },
        "description": {
            "ja": f"{display_name_ja}に関する情報",
            "en": f"Information related to {display_name_en}"
        },
        "examples": {
            "ja": [],
            "en": []
        },
        "prompts": {
            "extraction": {
                "ja": prompt_ja,
                "en": prompt_en
            }
        },
        "mapping": {
            "directMapping": mapping_data.get("directMapping", {}),
            "noteAppendMapping": mapping_data.get("noteAppendMapping", {})
        }
    }

    return definition

def main():
    # プロジェクトルートディレクトリ
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    # パス設定
    swift_file = project_root / "Sources/AITest/SubCategoryExtractionStructs.swift"
    content_info_file = project_root / "Sources/AITest/ContentInfo.swift"
    mappings_dir = project_root / "Sources/AITest/Mappings"
    output_dir = project_root / "Sources/AITest/CategoryDefinitions/subcategories"

    # 出力ディレクトリ作成
    output_dir.mkdir(parents=True, exist_ok=True)

    # 構造体定義を解析
    struct_fields = parse_struct_fields(swift_file)

    # サブカテゴリ情報を解析
    subcategory_info = parse_subcategory_info(content_info_file)

    # 全マッピングファイルを処理
    print(f"{Colors.BLUE}🔧 サブカテゴリ定義ファイルを生成中...{Colors.END}\n")
    print("=" * 80)

    mapping_files = sorted(mappings_dir.glob("*_mapping.json"))
    generated_count = 0

    for mapping_file in mapping_files:
        subcategory_id = mapping_file.stem.replace('_mapping', '')
        struct_name = get_struct_name_from_subcategory(subcategory_id)

        if struct_name not in struct_fields:
            print(f"{Colors.RED}❌ {subcategory_id}: 構造体 {struct_name} が見つかりません{Colors.END}")
            continue

        if subcategory_id not in subcategory_info:
            print(f"{Colors.YELLOW}⚠️  {subcategory_id}: サブカテゴリ情報が見つかりません{Colors.END}")
            continue

        # マッピングファイルを読み込み
        with open(mapping_file, 'r', encoding='utf-8') as f:
            mapping_data = json.load(f)

        # サブカテゴリ定義を生成
        definition = generate_subcategory_definition(
            subcategory_id,
            subcategory_info[subcategory_id],
            struct_fields[struct_name],
            mapping_data
        )

        # 出力
        output_file = output_dir / f"{subcategory_id}.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(definition, f, indent=2, ensure_ascii=False)
            f.write('\n')

        print(f"{Colors.GREEN}✅ {subcategory_id}{Colors.END}")
        generated_count += 1

    print("=" * 80)
    print(f"\n{Colors.BOLD}📊 生成結果{Colors.END}")
    print(f"  生成したファイル: {generated_count}個")
    print(f"  出力ディレクトリ: {output_dir}")

    if generated_count == 25:
        print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 全てのサブカテゴリ定義ファイルを生成しました！{Colors.END}")
    else:
        print(f"\n{Colors.YELLOW}⚠️  生成数が25個ではありません（{generated_count}個）{Colors.END}")

if __name__ == '__main__':
    main()
