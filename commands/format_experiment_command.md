# AIコマンド: フォーマット実験

## 概要
AI抽出改善のための実験パターン（抽象指示、厳格指示、人格指示、例示有無、フォーマット）の性能比較実験を実行し、包括的な分析レポートを作成するための指示書です。

**利用可能な引数**:
- `--method`: `json`, `generable`（デフォルト: `generable`）
- `--mode`: `simple`, `two-steps`（デフォルト: `simple`）
  - `simple`: 単純推定方式（従来の1段階抽出）
  - `two-steps`: 分離推定方式（カテゴリ判定→情報抽出の2段階処理）
- `--testcase`: `chat`, `creditcard`, `contract`, `password`, `voice`（デフォルト: `chat`）
- `--algos`: `abs`, `strict`, `persona`, `abs-ex`, `strict-ex`, `persona-ex`（デフォルト: 全6つ、two-stepsモードはabsのみ対応）
- `--levels`: `1`, `2`, `3`（デフォルト: 全3つ）
- `--language`: `ja`, `en`（デフォルト: `ja`）
- `--runs`: 各テストケースの実行回数（デフォルト: `1`）
- `--test-dir`: ログ出力ディレクトリの指定（オプション）

## 作業手順

### 1. 実験の実行

#### 1.1 拡張可能な実験実行スクリプト（推奨・新しい引数方式）

**単純推定方式（Simple Mode）- 従来の1段階抽出:**
```bash
# JSON methodで全アルゴリズム実行（20回ずつ）
python3 scripts/run_experiments.py --method json --mode simple --runs 20 --language ja

# two-stepsモードでgenerable methodで特定のアルゴリズムのみ実行
python3 scripts/run_experiments.py --method generable --mode two-steps --algos abs strict persona --runs 10 --language ja

# 全パラメータを明示的に指定
python3 scripts/run_experiments.py --method json --mode simple --testcase chat --algos abs strict persona abs-ex strict-ex persona-ex --levels 1 2 3 --runs 20 --language ja
```
**実行結果の確認:**
```bash
# 実行結果の確認（タイムスタンプ付きテストディレクトリ内）
ls -la test_logs/
ls -la test_logs/*/
```

#### 1.3 外部LLM実験の実行（AI置き換え実験・新しい引数方式）

##### 目的
FoundationModelsの性能を客観的に評価するため、外部ローカルLLM（gpt-oss-20b）との性能比較を実施します。AI部分のみを置き換えることで、同じテストケースで異なるAIの性能を比較できます。

##### 手法
- 既存の実験手順は一切変更せず、AI部分のみを外部LLMに置き換え
- ログ形式、レポート生成、pending項目検証などは既存の手順と同じ
- 外部LLMはHTTP経由でOpenAI互換APIを使用

##### コマンドの違い
既存のコマンドに`--external-llm-url`と`--external-llm-model`オプションを追加するだけです：

**単一実験（外部LLM版）- Simple Mode:**
```bash
# FoundationModels: python3 scripts/run_experiments.py --method json --mode simple --runs 20 --language ja
# 外部LLM: python3 scripts/run_experiments.py --method json --mode simple --runs 20 --language ja --external-llm-url "http://182.171.83.172" --external-llm-model "openai/gpt-oss-20b"
```

**単一実験（外部LLM版）- Two-Steps Mode:**
```bash
# FoundationModels: python3 scripts/run_experiments.py --method json --mode two-steps --runs 20 --language ja
# 外部LLM: python3 scripts/run_experiments.py --method json --mode two-steps --runs 20 --language ja --external-llm-url "http://182.171.83.172" --external-llm-model "openai/gpt-oss-20b"
```

##### その他の手順
- **レポート生成**: 既存の手順と同じ（`python3 scripts/generate_combined_report.py test_logs/202510180757_external_llm_experiment`）
- **pending項目検証**: 既存の手順と同じ（`python3 scripts/extract_pending_items.py "level1" "title" --log-dir "test_logs/202510180757_external_llm_experiment" --all-items`）
- **ログ形式**: 既存の形式と同じ（`{testcase}_{algo}_{method}_{lang}_{level}_{run#}.json`）

**注意**: 外部LLM実験は、AI部分のみを置き換えるだけで、他の手順には一切影響を与えません。

#### 1.4 AITestAppでの直接実行（デバッグ・単体テスト用）

**Simple Mode（単純推定方式）:**
```bash
# プロンプトデバッグ（指定したパターンのプロンプトを確認）
swift run AITestApp --debug-prompt --method json --mode simple --testcase chat --language ja

# 特定パターンの実験実行（全アルゴリズム）
swift run AITestApp --method json --mode simple --testcase chat --language ja --algos abs strict persona --runs 5

# 外部LLMでの実行
swift run AITestApp --method json --mode simple --testcase chat --language ja --external-llm-url "http://182.171.83.172" --external-llm-model "openai/gpt-oss-20b"

# 統一ディレクトリでの実行（推奨）
swift run AITestApp --method generable --mode simple --testcase chat --language ja --algos abs strict persona abs-ex strict-ex persona-ex --runs 3 --test-dir test_logs/unified_experiment

# Two-Steps Mode: プロンプトデバッグ
swift run AITestApp --debug-prompt --method json --mode two-steps --testcase chat --language ja
```

#### 1.5 ログファイルの場所（最新実装）
- **実験実行ディレクトリ**: `test_logs/yyyymmddhhmm_実験名/`（統一されたディレクトリ）
- **最新実行ディレクトリ**: `test_logs/latest`（シンボリックリンク）
- **構造化JSONログ**: `test_logs/yyyymmddhhmm_実験名/{testcase}_{algo}_{method}_{lang}_{level}_{run#}.json`
  - 例: `test_logs/202510191631_generable_ja/chat_abs_generable_ja_level1_run1.json`
  - 例: `test_logs/202510191631_generable_ja/chat_strict_generable_ja_level2_run3.json`
  - 例: `test_logs/202510191631_generable_ja/chat_persona-ex_generable_ja_level3_run2.json`
- **統合レポート**: `test_logs/yyyymmddhhmm_実験名/parallel_format_experiment_report.html`
- **詳細メトリクス**: `test_logs/yyyymmddhhmm_実験名/detailed_metrics.json`

**重要**: 最新の実装では、すべてのアルゴリズムが統一されたディレクトリに出力されます。`--test-dir`引数でディレクトリを指定することで、時間経過に関係なく同じディレクトリにログが出力されます。

### 2. レポート生成

#### 2.1 統合レポートの生成
実験完了後、統合レポートを生成してください：

```bash
# 特定の実験ディレクトリを指定
python3 scripts/generate_combined_report.py test_logs/202510180757_external_llm_experiment
```

#### 2.2 レポートの確認
生成されたレポートを確認してください：

```bash
# 特定の実験ディレクトリのレポートを開く
open test_logs/202510180757_external_llm_experiment/parallel_format_experiment_report.html
```

### 3. pending項目のAI検証と更新（手動検証による正確な判定）
titleとnote項目それぞれについて、各levelごとに以下の手順でstatusの更新を行う。(2項目 x 3レベルの組み合わせで、6回以下の手順を繰り返すこと)

#### 3.1 項目の抽出（statusに関係なく）

指定したテストケースと項目について、全データをCSV形式で抽出します：

```bash
# Level 1のtitle項目の全データを抽出の例
python3 scripts/extract_pending_items.py "level1" "title" --log-dir "test_logs/202510180757_external_llm_experiment" --all-items
```

#### 3.2 手動検証の実施（重要：プログラム的処理は禁止）
抽出された項目について、**必ず手動で**対応するテストデータと実際に抽出された値を比較し、以下の観点で検証してください：

**⚠️ 重要な注意事項**:
- **検索や正規表現による一括処理は禁止**
- **意味的な内容を自分で確認して判断する必要がある**
- **各項目を個別に検証し、内容を理解した上で判定する**

**検証手順**:

1. **テストデータの確認**
   ```bash
   # 対応するテストデータファイルの確認の例
   cat Tests/TestData/Chat/Level1_Basic.txt
   cat Tests/TestData/CreditCard/Level2_Intermediate.txt
   cat Tests/TestData/Contract/Level3_Advanced.txt
   ```

2. **抽出値の意味的整合性判定**
   - **title項目**: テストデータに記載されているサービス名・システム名と意味的に整合するか
   - **note項目**: テストデータに記載されている補足情報・注意事項と意味的に整合するか

**判定基準**:

| 抽出値の状態 | 判定 | 理由 |
|-------------|------|------|
| テストデータの内容と**意味的に整合** | `correct` | 自然言語記述のため、表現の違いは許容 |
| テストデータの内容と**意味的に不整合** | `wrong` | 内容が間違っている |
| `null`、`None`、`nil`、空文字列 | `missing` | テストデータに記述があるが抽出されていない |

**意味的整合性の例**:

**Level 1のtitle項目**:
- ✅ `"AWS EC2"` → `correct`（テストデータに「AWS EC2」の記述あり）
- ✅ `"AWS EC2サーバー"` → `correct`（「AWS EC2」の詳細表現として意味的に整合）
- ❌ `"AWO"` → `wrong`（テストデータに該当する記述なし）

**Level 1のnote項目**:
- ✅ `"AWS EC2にログインするには"` → `correct`（テストデータの内容と整合）
- ✅ `"AWS EC2にログインするための注意事項"` → `correct`（テストデータの内容を要約した表現）
- ❌ `"ToDoや注意事項などの補足情報の要約"` → `wrong`（テストデータの内容と不整合）

#### 3.3 検証結果CSVファイルの作成（コンパクト形式）
手動検証の結果を以下の形式でCSVファイルに保存してください：

```csv
ファイル名,判定,理由
chat_abs_generable_ja_level1_run1.json,title,wrong,テストデータに「AWO」の記述なし
chat_strict_generable_ja_level1_run15.json,note,wrong,テストデータの内容と不整合
chat_abs_generable_ja_level2_run17.json,title,missing,テストデータに「AWS EC2インスタンス」の記述があるが抽出されていない
```

**CSVファイル作成時の注意事項**:
- **correct以外のケースのみ記載**（correctの場合は記載不要）
- **各項目を個別に検証した結果のみを記録**
- **理由欄には具体的な判定根拠を記載**
- **意味的整合性を重視した判定結果を記録**
- **作業完了後、中間CSVファイルは自動削除されます**

#### 3.4 全項目のstatus更新（コンパクト形式対応）
検証結果CSVファイルを元に、JSONログファイルの全項目のステータスを一括更新します：

```bash
# 検証結果CSVファイルを元にファイルを更新（項目名を指定） の例
python3 scripts/update_pending_status.py level1_title_verification_compact.csv test_logs/202510180757_external_llm_experiment title
```
# 作業完了後、中間ファイルを自動削除
python3 scripts/cleanup_intermediate_files.py
```

### 4. 更新されたログの再集計（pending項目更新後）

#### 4.1 更新されたログの再集計
pending項目を更新した後、プログラムで再集計を実行してください：

```bash
# 統合レポートの再生成（最新実行ディレクトリの例）
python3 scripts/generate_combined_report.py test_logs/latest
```

#### 4.2 再集計結果の確認
更新されたレポートを確認してください：

```bash
# 統合レポートの確認（最新ディレクトリのレポートを開く）
open test_logs/latest/parallel_format_experiment_report.html
```

### 6. 最終レポートの作成
以下の集計結果分析を実施し、レポートに加筆し、最終レポートを完成させてください。

#### 5.1 プログラム集計結果の確認
生成されたレポートから以下の情報を確認してください：

1. **正規化スコア**: 各パターンの正規化スコア（主要評価指標）
2. **正解率**: 期待される項目が正しく抽出された割合
3. **誤り率**: 抽出された項目の値が間違っている割合
4. **欠落率**: 期待される項目が抽出されなかった割合
5. **過剰抽出率**: 期待されない項目が誤って抽出された割合
6. **レベル別性能**: Level 1/2/3での性能差
7. **Algo別性能**: 各アルゴリズム（abs、strict、persona等）の性能差

#### 5.2 具体的な問題点の指摘と原因考察
集計結果から以下の具体的な問題を特定し、詳細な原因考察を行ってください：

1. **誤抽出の具体例と原因分析**
   - 例：title: "accoca" → 期待値: "MASTERCARD"
   - 原因：プロンプト理解の失敗、文脈の誤解釈、フィールド定義の混乱

2. **レベル別性能差の原因分析**
   - 問題(過剰・欠落・誤り)が起きやすい項目の特定と原因の分析
   - レベル変化による精度や問題項目の変化の分析
   - 複雑さによる抽出精度の変化

#### 5.3 最終レポートの完成
```bash
# 最終レポートを確認（AI加筆後の最終版）
open reports/final_format_experiment_report.html
```

**注意**: この作業はAI（あなた）による手動分析と加筆が必須です。プログラムによる自動生成だけでは、深い洞察や考察を含む包括的なレポートは作成できません。

## 参考ファイル

### 共通コアファイル
- `Sources/AITest/ModelExtractor.swift`: モデル抽象化インターフェース
- `Sources/AITest/UnifiedExtractor.swift`: 統一抽出フロー
- `Sources/AITest/FoundationModelsExtractor.swift`: FoundationModels抽出実装
- `Sources/AITest/ExternalLLMExtractor.swift`: 外部LLM抽出実装
- `Sources/AITest/JSONExtractor.swift`: JSON解析・サニタイズ処理
- `Sources/AITestApp/main.swift`: コンソールアプリケーション
- `Sources/AITest/PatternDefinitions.swift`: 実験パターン定義
- `docs/EXPERIMENT_PATTERNS.md`: 実験パターン仕様書
- `docs/TWO_STEPS_EXTRACTION_SPEC.md`: 2段階抽出仕様書

### pending項目検証用スクリプト

- `scripts/extract_pending_items.py`: pending項目抽出スクリプト（中間ファイル自動削除機能付き）
- `scripts/update_pending_status.py`: pending項目ステータス更新スクリプト（中間ファイル自動削除機能付き）
- `scripts/cleanup_intermediate_files.py`: 中間ファイル自動削除スクリプト
- `pending_verification_results.csv`: 検証結果CSVファイル（手動作成、作業完了後自動削除）

