# AIコマンド: 2ステップテスト

## 概要
two-steps(json/ja)モードのチューニングのため、指定されたテストケースを網羅的に実行し、その結果を統計処理してレポートを完成させる。

**⚠️ 重要な注意事項**: このコマンドの実行を指示された場合、以下の全手順を遂行すること：
1. 実験の実行（手順1）
2. レポート生成（手順2）
3. pending項目のAIによる検証と更新（手順3）
4. 更新されたログの再集計（手順4）
5. 最終レポートの作成（手順5）

**固定パラメータ**: `--method json --mode two-steps --language ja`  
**指定可能な引数**: `--testcase` (chat/creditcard/contract/password/voice), `--levels` (1/2/3), `--runs` (実行回数)

**注意**: two-stepsモードでは`--algos`パラメータは不要です（指定しても無視されます）。

## 作業手順

### 1. 実験の実行

```bash
# 全テストケース・全レベルを実行
python3 scripts/run_experiments.py --method json --mode two-steps --runs 20 --language ja

# 特定のテストケース・レベルを実行
python3 scripts/run_experiments.py --method json --mode two-steps --testcase chat --levels 1 --runs 20 --language ja
```

**実行結果ディレクトリ**: `run_experiments.py`が自動生成するディレクトリ名は以下の形式です：
- 形式: `test_logs/{日時}_{method}_{language}_{mode}_{ランダム4文字}/`
- 例: `test_logs/202511270642_json_ja_two-steps_a3f2/`
- 日時: `yyyymmddHHMM`形式（例: 202511270642）
- ランダム4文字: 小文字英数字（例: a3f2）

### 2. レポート生成

```bash
python3 scripts/generate_combined_report.py test_logs/202511270642_json_ja_two-steps_a3f2
open test_logs/202511270642_json_ja_two-steps_a3f2/parallel_format_experiment_report.html
```

### 3. pending項目のAIによる検証と更新

titleとnote項目について、各levelごとに以下の2段階の手順でstatusを更新する。

#### 3.1 項目一覧CSVファイルの作成

```bash
# CSVファイルに出力するため、リダイレクトを使用
python3 scripts/extract_pending_items.py "level1" "title" --log-dir "test_logs/202511270642_json_ja_two-steps_a3f2" --all-items > level1_title_items.csv
python3 scripts/extract_pending_items.py "level1" "note" --log-dir "test_logs/202511270642_json_ja_two-steps_a3f2" --all-items > level1_note_items.csv
```

このCSVファイルには、検証対象の全項目が含まれます（ファイル名、値、status）。

#### 3.2 AIによる直接検証

**AIが直接CSVファイルを読み込んで、各項目を検証し、検証結果CSVを作成します。**

**⚠️ 重要な禁止事項**:
- **スクリプトを利用した一括処理は禁止です**
- **各CSVファイルを一つずつ順番に処理し、AIが直接ファイルを読み込んで検証を行ってください**
- **もしスクリプトを利用した一括処理を実施した場合は、違反として報告してください**

**重要**: `extract_pending_items.py`の出力したファイルを**一つずつ順番に処理**します。一つ目のファイルの検証が完了してから、次のファイルを処理してください。

以下の手順で、各CSVファイルごとに検証を実施してください：

**ファイル1: `level1_title_items.csv` の検証**

1. **CSVファイルの読み込み**
   - `level1_title_items.csv` を読み込む
   - CSVファイルの形式: `ファイル名,値,status`

2. **テストデータの確認**
   - テストデータファイルを読み込む: `Tests/TestData/Chat/Level1_Basic.txt`
   - テストデータの内容を確認し、`title`項目の期待値を理解する

3. **各項目の検証**
   - CSVファイルに記載された各項目について、以下の手順で検証する：
     a. 抽出値（CSVの「値」列）を確認
     b. テストデータと比較して、意味的な整合性を判定
     c. 判定結果（`correct`/`wrong`/`missing`）を決定
     d. 判定理由を具体的に記載（各項目ごとに固有の理由）

4. **検証結果CSVファイルの作成**
   - `correct`以外のケースのみ記載（コンパクト形式）
   - ファイル名: `level1_title_verification_compact.csv`
   - 形式: `ファイル名,項目,判定,理由`

**ファイル2: `level1_note_items.csv` の検証**

1. **CSVファイルの読み込み**
   - `level1_note_items.csv` を読み込む
   - CSVファイルの形式: `ファイル名,値,status`

2. **テストデータの確認**
   - テストデータファイルを読み込む: `Tests/TestData/Chat/Level1_Basic.txt`
   - テストデータの内容を確認し、`note`項目の期待値を理解する

3. **各項目の検証**
   - CSVファイルに記載された各項目について、以下の手順で検証する：
     a. 抽出値（CSVの「値」列）を確認
     b. テストデータと比較して、意味的な整合性を判定
     c. 判定結果（`correct`/`wrong`/`missing`）を決定
     d. 判定理由を具体的に記載（各項目ごとに固有の理由）

4. **検証結果CSVファイルの作成**
   - `correct`以外のケースのみ記載（コンパクト形式）
   - ファイル名: `level1_note_verification_compact.csv`
   - 形式: `ファイル名,項目,判定,理由`

**⚠️ 重要な注意事項**:
- **各項目を個別に検証し、抽出値とテストデータを比較して判定する**
- **判定理由は、抽出値とテストデータの具体的な内容に基づいて記載する**
- **同一の理由の使い回しは禁止**（例：「意味的に整合」を全項目に使用することを禁止）
- **各項目ごとに、その項目固有の判定理由を明記する**

**判定基準**:

| 抽出値の状態 | 判定 | 理由記載の要件 |
|-------------|------|---------------|
| テストデータと意味的に整合 | `correct` | 抽出値とテストデータの具体的な対応関係を記載 |
| テストデータと意味的に不整合 | `wrong` | 抽出値とテストデータの具体的な不一致点を記載 |
| `null`/`None`/`nil`/空文字列 | `missing` | テストデータのどの部分が抽出されなかったかを記載 |

**判定理由の記載例**:
```csv
ファイル名,項目,判定,理由
chat_abs_json_ja_level1_run1.json,title,correct,抽出値「AWS EC2」はテストデータの「AWS EC2にログインするには」の記述と対応
chat_abs_json_ja_level1_run2.json,title,wrong,抽出値「AWO」はテストデータに該当する記述が存在しない
```

**禁止事項**: 「意味的に整合」などの汎用的な理由を全項目に使い回すこと

#### 3.3 全項目のstatus更新

```bash
python3 scripts/update_pending_status.py level1_title_verification_compact.csv test_logs/202511270642_json_ja_two-steps_a3f2 title
python3 scripts/update_pending_status.py level1_note_verification_compact.csv test_logs/202511270642_json_ja_two-steps_a3f2 note
python3 scripts/cleanup_intermediate_files.py
```

### 4. 更新されたログの再集計

```bash
python3 scripts/generate_combined_report.py test_logs/202511270642_json_ja_two-steps_a3f2
open test_logs/202511270642_json_ja_two-steps_a3f2/parallel_format_experiment_report.html
```

### 5. 最終レポートの作成

集計結果から以下の分析を実施し、レポートに加筆する：
1. **正規化スコア**: 各パターンの正規化スコア（主要評価指標）
2. **レベル別性能**: Level 1/2/3での性能差と原因分析
3. **誤抽出の具体例**: 誤抽出の具体例と原因分析
4. **two-stepsモード特有の問題**: カテゴリ判定精度と情報抽出精度の関係

**注意**: この作業はAIによる手動分析と加筆が必須です。

