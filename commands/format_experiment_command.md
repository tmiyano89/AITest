# AIコマンド: @Guideマクロ改善実験

## 概要
@Guideマクロ改善のための実験パターン（抽象指示、厳格指示、人格指示、例示有無、フォーマット）の性能比較実験を実行し、包括的な分析レポートを作成するための指示書です。

**利用可能な引数**:
- `--method`: `json`, `generable`, `yaml`（デフォルト: `generable`）
- `--testcases`: `chat`, `creditcard`, `contract`, `password`, `voice`（デフォルト: `chat`）
- `--algos`: `abs`, `strict`, `persona`, `abs-ex`, `strict-ex`, `persona-ex`（デフォルト: 全6つ）
- `--levels`: `1`, `2`, `3`（デフォルト: 全3つ）
- `--language`: `ja`, `en`（デフォルト: `ja`）

## 作業手順

### 1. 実験の実行

#### 1.1 拡張可能な実験実行スクリプト（推奨・新しい引数方式）
```bash
# JSON methodで全アルゴリズム実行（20回ずつ）
python3 scripts/run_experiments.py --method json --runs 20 --language ja

# generable methodで特定のアルゴリズムのみ実行
python3 scripts/run_experiments.py --method generable --algos abs strict persona --runs 10 --language ja

# 特定のテストケースとレベルで実行
python3 scripts/run_experiments.py --method json --testcases chat contract --levels 1 2 --runs 5 --language ja

# 全パラメータを明示的に指定
python3 scripts/run_experiments.py --method json --testcases chat --algos abs strict persona abs-ex strict-ex persona-ex --levels 1 2 3 --runs 20 --language ja
```

#### 1.2 並列実行スクリプト（新しい引数方式）
```bash
# FoundationModels: 並列実行で全アルゴリズム実行（20回ずつ）
python3 scripts/parallel_experiment_manager.py --method json --runs 20 --language ja

# 特定のアルゴリズムのみ並列実行
python3 scripts/parallel_experiment_manager.py --method generable --algos abs strict persona --runs 10 --language ja

# 特定のテストケースとレベルで並列実行
python3 scripts/parallel_experiment_manager.py --method json --testcases chat contract --levels 1 2 --runs 5 --language ja

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

**単一実験（外部LLM版）:**
```bash
# FoundationModels: python3 scripts/run_experiments.py --method json --runs 20 --language ja
# 外部LLM: python3 scripts/run_experiments.py --method json --runs 20 --language ja --external-llm-url "http://182.171.83.172" --external-llm-model "openai/gpt-oss-20b"
```

**並列実行（外部LLM版）:**
```bash
# FoundationModels: python3 scripts/parallel_experiment_manager.py --method json --runs 20
# 外部LLM: python3 scripts/parallel_experiment_manager.py --method json --runs 20 --external-llm-url "http://182.171.83.172" --external-llm-model "openai/gpt-oss-20b"
```

##### その他の手順
- **レポート生成**: 既存の手順と同じ（`python3 scripts/generate_combined_report.py test_logs/202510180757_external_llm_experiment`）
- **pending項目検証**: 既存の手順と同じ（`python3 scripts/extract_pending_items.py "level1" "title" --log-dir "test_logs/202510180757_external_llm_experiment" --all-items`）
- **ログ形式**: 既存の形式と同じ（`{pattern}_{algo}_{method}_{lang}_{level}_{run#}.json`）

**注意**: 外部LLM実験は、AI部分のみを置き換えるだけで、他の手順には一切影響を与えません。

#### 1.4 AITestAppでの直接実行（デバッグ・単体テスト用）

```bash
# プロンプトデバッグ（指定したパターンのプロンプトを確認）
swift run AITestApp --debug-prompt --method json --testcase strict --language ja

# 単一テスト実行（デバッグ用）
swift run AITestApp --debug-single --method json --testcase strict --language ja

# 特定パターンの実験実行
swift run AITestApp --method json --testcase strict --language ja --runs 5

# 外部LLMでの実行
swift run AITestApp --method json --testcase strict --language ja --external-llm-url "http://182.171.83.172" --external-llm-model "openai/gpt-oss-20b"
```

#### 1.5 ログファイルの場所（最新実装）
- **実験実行ディレクトリ**: `test_logs/yyyymmddhhmm_実験名/`
- **最新実行ディレクトリ**: `test_logs/latest`（シンボリックリンク）
- **構造化JSONログ**: `test_logs/yyyymmddhhmm_実験名/{testcase}_{algo}_{method}_{lang}_{level}_{run#}.json`
  - 例: `test_logs/202510171800_multi_experiments/chat_abs_gen_ja_level1_run1.json`
  - 例: `test_logs/202510180757_external_llm_experiment/chat_abs_json_ja_level1_run1.json`
  - 例: `test_logs/202501181952_json_experiment/chat_strict_json_ja_level1_run1.json`
- **統合レポート**: `test_logs/yyyymmddhhmm_実験名/parallel_format_experiment_report.html`
- **詳細メトリクス**: `test_logs/yyyymmddhhmm_実験名/detailed_metrics.json`

### 2. レポート生成

#### 2.1 統合レポートの生成
実験完了後、統合レポートを生成してください：

```bash
# 統合レポートの生成（最新実行ディレクトリを利用）
python3 scripts/generate_combined_report.py test_logs/latest

# または特定の実験ディレクトリを指定
python3 scripts/generate_combined_report.py test_logs/202510180757_external_llm_experiment
```

#### 2.2 レポートの確認
生成されたレポートを確認してください：

```bash
# 統合レポートの確認（最新ディレクトリのレポートを開く）
open test_logs/latest/parallel_format_experiment_report.html

# または特定の実験ディレクトリのレポートを開く
open test_logs/202510180757_external_llm_experiment/parallel_format_experiment_report.html
```

### 3. pending項目のAI検証と更新（手動検証による正確な判定）

#### 3.1 全項目の抽出（statusに関係なく）
指定したテストケースと項目名のすべてのデータをCSV形式で抽出します：

```bash
# Level 1のtitle項目の全データを抽出
python3 scripts/extract_pending_items.py "level1" "title" --log-dir "test_logs/202510180757_external_llm_experiment" --all-items

# Level 1のnote項目の全データを抽出
python3 scripts/extract_pending_items.py "level1" "note" --log-dir "test_logs/202510180757_external_llm_experiment" --all-items

# Level 2のtitle項目の全データを抽出
python3 scripts/extract_pending_items.py "level2" "title" --log-dir "test_logs/202510180757_external_llm_experiment" --all-items

# Level 2のnote項目の全データを抽出
python3 scripts/extract_pending_items.py "level2" "note" --log-dir "test_logs/202510180757_external_llm_experiment" --all-items

# Level 3のtitle項目の全データを抽出
python3 scripts/extract_pending_items.py "level3" "title" --log-dir "test_logs/202510180757_external_llm_experiment" --all-items

# Level 3のnote項目の全データを抽出
python3 scripts/extract_pending_items.py "level3" "note" --log-dir "test_logs/202510180757_external_llm_experiment" --all-items
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
- ✅ `"AWS"` → `correct`（「AWS EC2」の略称として意味的に整合）
- ✅ `"AWS EC2サーバー"` → `correct`（「AWS EC2」の詳細表現として意味的に整合）
- ❌ `"AWO"` → `wrong`（テストデータに該当する記述なし）
- ❌ `"サーバー"` → `wrong`（具体的なサービス名ではない）

**Level 1のnote項目**:
- ✅ `"AWS EC2にログインするには"` → `correct`（テストデータの内容と整合）
- ✅ `"アカウントはadmin/SecurePass18329です"` → `correct`（テストデータの内容と整合）
- ✅ `"よろしく！"` → `correct`（テストデータに「よろしく！」の記述あり）
- ✅ `"AWS EC2にログインするための注意事項"` → `correct`（テストデータの内容を要約した表現）
- ❌ `"ToDoや注意事項などの補足情報の要約"` → `wrong`（テストデータの内容と不整合）

#### 3.3 検証結果CSVファイルの作成（コンパクト形式）
手動検証の結果を以下の形式でCSVファイルに保存してください：

```csv
ファイル名,判定,理由
chat_abs_generable_ja_level1_run1.json,title,wrong,テストデータに「AWO」の記述なし
chat_twosteps_generable_ja_level1_run15.json,note,wrong,テストデータの内容と不整合
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
# 検証結果CSVファイルを元にファイルを更新（項目名を指定）
python3 scripts/update_pending_status.py level1_title_verification_compact.csv test_logs/202510180757_external_llm_experiment title
python3 scripts/update_pending_status.py level1_note_verification_compact.csv test_logs/202510180757_external_llm_experiment note
python3 scripts/update_pending_status.py level2_title_verification_compact.csv test_logs/202510180757_external_llm_experiment title
python3 scripts/update_pending_status.py level2_note_verification_compact.csv test_logs/202510180757_external_llm_experiment note

# 作業完了後、中間ファイルを自動削除
python3 scripts/cleanup_intermediate_files.py
```

**更新スクリプトの機能**:
- CSVファイルの検証結果を読み込み（correct以外のケースのみ）
- ログディレクトリから対象JSONファイルを検索
- 指定された項目名のフィールドを検索
- CSVファイルに記載がある項目：指定されたステータスに更新
- CSVファイルに記載がない項目：`correct`に修正
- 更新されたJSONファイルを保存
- 更新状況とエラー件数を表示
- **作業完了後、中間CSVファイルは自動削除されます**

#### 3.5 検証プロセスの品質管理

**検証完了の確認項目**:
- [ ] すべての項目を手動で検証済み
- [ ] テストデータの内容を確認済み
- [ ] 意味的整合性を考慮した判定を実施
- [ ] 検索や正規表現による一括処理は使用していない
- [ ] 各判定に具体的な理由を記載
- [ ] CSVファイルの形式が正しい

**検証品質の向上ポイント**:
1. **複数回の確認**: 疑わしい項目は複数回確認する
2. **文脈の理解**: テストデータ全体の文脈を理解してから判定する
3. **表現の多様性**: 自然言語の表現の違いを許容する
4. **一貫性の維持**: 同様の項目は一貫した基準で判定する

**詳細なスキーマ定義**: [LOG_SCHEMA.md](../docs/LOG_SCHEMA.md)を参照してください。

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

### 5. 集計結果の分析

#### 5.1 プログラム集計結果の確認
生成されたレポートから以下の情報を確認してください：

1. **正規化スコア**: 各パターンの正規化スコア（主要評価指標）
2. **正解率**: 期待される項目が正しく抽出された割合
3. **誤り率**: 抽出された項目の値が間違っている割合
4. **欠落率**: 期待される項目が抽出されなかった割合
5. **過剰抽出率**: 期待されない項目が誤って抽出された割合
6. **レベル別性能**: Level 1/2/3での性能差
7. **Algo別性能**: 各アルゴリズム（abs、strict、persona等）の性能差

#### 5.2 パターン別性能比較
集計結果から以下の観点で各パターンの性能を比較してください：

1. **指示タイプ別比較（抽象 vs 厳格 vs 人格）**
   - 抽象指示: 最小限の指示でAIの創造性を最大限発揮
   - 厳格指示: 詳細な制約ルールで出力品質を向上
   - 人格指示: 専門家の役割を設定して関連知識を活性化

2. **例示効果の比較（例示なし vs 例示あり）**
   - 例示なし: 基本性能の測定
   - 例示あり: few-shot学習による性能向上効果

3. **フォーマット別比較（@Generable vs JSON vs YAML）**
   - @Generable: 型安全な構造化抽出（FoundationModels専用）
   - JSON: テキストベースの構造化抽出（外部LLM互換）
   - YAML: 人間可読な構造化抽出


#### 5.3 具体的な問題点の指摘と原因考察
集計結果から以下の具体的な問題を特定し、詳細な原因考察を行ってください：

1. **誤抽出の具体例と原因分析**
   - 例：title: "accoca" → 期待値: "MASTERCARD"
   - 原因：プロンプト理解の失敗、文脈の誤解釈、フィールド定義の混乱

2. **フィールド混同の具体例と原因分析**
   - 例：userIDにカード番号が抽出される
   - 原因：フィールド定義の理解不足、文脈の誤解釈

3. **レベル別性能差の原因分析**
   - Level 1での過剰抽出の原因
   - Level 3での精度向上の要因
   - 複雑さによる抽出精度の変化

4. **パターン別性能差の原因分析**
   - 抽象指示 vs 厳格指示の効果差
   - 例示あり vs 例示なしの効果差
   - 人格指示の有効性

5. **フォーマット別性能差の原因分析**
   - @Generable vs JSON vs YAMLの性能差
   - プロンプトテンプレートの効果
   - 外部LLM互換性の影響

### 6. 最終レポートの作成

#### 6.1 集計結果の分析とレポート加筆
プログラムによる集計結果を基に、以下の作業を実施してください：

1. **エグゼクティブサマリー**
   - 実験の概要と主要な発見
   - 各パターンの性能比較
   - 推奨事項

2. **詳細分析セクション**
   - パターン別の詳細な性能分析
   - レベル別の性能分析
   - Algo別の性能分析
   - 正規化スコアの詳細分析

3. **具体的な問題点の指摘**
   - 誤抽出の具体例と原因分析
   - フィールド混同の具体例と原因分析
   - レベル別性能差の原因分析
   - パターン別性能差の原因分析

4. **エラーパターン分析**
   - 発生したエラーの詳細分析
   - エラーの原因と対策
   - 改善提案
   - 誤抽出の根本原因分析

5. **統計的分析結果**
   - 正規化スコアの統計
   - 性能メトリクスの分析
   - 相関分析の結果
   - レベル別・Algo別の詳細統計

6. **pending項目のAI検証結果（title、note）**
   - 各pending項目の詳細検証
   - correct/wrong判定の根拠
   - 検証結果の統計分析
   - AI検証による精度向上の効果

7. **推奨事項と改善提案**
   - 最適なパターンの選択指針
   - プロンプト改善の提案
   - システム改善の提案
   - 誤抽出防止の具体的対策

#### 6.2 最終レポートの完成
```bash
# 最終レポートを確認（AI加筆後の最終版）
open reports/final_format_experiment_report.html
```

**注意**: この作業はAI（あなた）による手動分析と加筆が必須です。プログラムによる自動生成だけでは、深い洞察や考察を含む包括的なレポートは作成できません。

## 参考ファイル

- `test_logs/yyyymmddhhmm_実験名/`: 実験実行ディレクトリ（実行後に生成）
- `test_logs/yyyymmddhhmm_実験名/*.json`: 構造化JSONログ（実行後に生成）
- `test_logs/yyyymmddhhmm_実験名/parallel_format_experiment_report.html`: 統合レポート（実行後に生成）
- `test_logs/yyyymmddhhmm_実験名/detailed_metrics.json`: 詳細メトリクス（実行後に生成）
- `reports/final_format_experiment_report.html`: 最終レポート（AI分析・加筆後）
- `Sources/AITest/Prompts/`: プロンプトテンプレートファイル（ファイルベース）
  - `{type}_{method}_{language}.txt`形式（例: `strict_json_ja.txt`）
  - 基本指示文、JSONフォーマット、YAMLフォーマットに対応
- `Sources/AITest/AccountExtractor.swift`: 抽出方法実装
- `Sources/AITestApp/main.swift`: コンソールアプリケーション
- `Sources/AITest/PatternDefinitions.swift`: 実験パターン定義
- `docs/EXPERIMENT_PATTERNS.md`: 実験パターン仕様書

### pending項目検証用スクリプト

- `scripts/extract_pending_items.py`: pending項目抽出スクリプト（中間ファイル自動削除機能付き）
- `scripts/update_pending_status.py`: pending項目ステータス更新スクリプト（中間ファイル自動削除機能付き）
- `scripts/cleanup_intermediate_files.py`: 中間ファイル自動削除スクリプト
- `pending_verification_results.csv`: 検証結果CSVファイル（手動作成、作業完了後自動削除）

