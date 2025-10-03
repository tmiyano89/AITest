# AIコマンド: FoundationModels フォーマット実験

## 概要
FoundationModelsの抽出方法（@Generableマクロ、JSON形式、YAML形式）とプロンプト言語（日本語、英語）の性能比較実験を実行し、包括的な分析レポートを作成するための指示書です。

## 作業手順

### 1. フォーマット実験の実行

#### 1.1 並列実行による高速化
```bash
# 並列実行スクリプトを使用（高速化）
./scripts/parallel_format_experiment.sh

# 実行結果の確認
ls -la logs/
ls -la reports/
```

#### 1.2 ログファイルの場所
- **テスト実行ディレクトリ**: `test_logs/test_yyyymmddhhmm/`
- **構造化JSONログ**: `test_logs/test_yyyymmddhhmm/{method}_{language}_chat_level1_1.json` など
- **個別HTMLレポート**: `test_logs/test_yyyymmddhhmm/{method}_{language}_format_experiment_report.html`
- **統合レポート**: `reports/parallel_format_experiment_report.html`

### 2. pending項目のAI検証と更新

#### 2.1 pending項目の特定と検証
AITestAppのログからpending項目を特定し、AIによる検証を実施してください：

1. **pending項目の検索**
   ```bash
   # pending項目を含むJSONファイルを検索
   find test_* -name "*.json" -exec grep -l '"status" : "pending"' {} \;
   ```

2. **各pending項目の詳細確認**
   ```bash
   # 各pending項目の詳細確認
   for json_file in $(find test_* -name "*.json" -exec grep -l '"status" : "pending"' {} \;); do
       echo "=== $json_file ==="
       cat "$json_file" | jq '.expected_fields[] | select(.status == "pending")'
       echo ""
   done
   ```

#### 2.2 AI検証の実施
各pending項目（title、note）について、対応する[テストデータ](../Tests/TestData/)と実際に抽出された値を比較し、以下の観点で検証してください：

1. **内容の正確性**: 抽出された値が意味的に正しいかどうか（自由形式の記述のため様々な表現が正しい場合がある）

#### 2.3 pending項目のstatus更新
各JSONファイルのpending項目のstatusを更新してください：

**更新手順**:
1. 各JSONファイルのpending項目を確認
2. 対応するテストデータと比較してcorrect/wrongを判定
3. JSONファイル内のstatusを`pending`から`correct`または`wrong`に更新
4. 更新したJSONファイルを保存

**詳細なスキーマ定義**: [LOG_SCHEMA.md](../docs/LOG_SCHEMA.md)を参照してください。

### 3. プログラムによる集計実行

#### 3.1 更新されたログの集計
pending項目を更新した後、プログラムで集計を実行してください：

```bash
# 統合レポートの生成
python3 scripts/generate_combined_report.py test_* reports/
```

#### 3.2 集計結果の確認
生成されたレポートを確認してください：

```bash
# 統合レポートの確認
open reports/parallel_format_experiment_report.html
```

### 4. 集計結果の分析

#### 4.1 プログラム集計結果の確認
生成されたレポートから以下の情報を確認してください：

1. **抽出すべき項目の成功率**: 期待される項目が正しく抽出された割合
2. **抽出すべきでない項目の抽出率**: 期待されない項目が誤って抽出された割合
3. **抽出した項目の値の正確さ**: 抽出された項目の値が正しい割合
4. **項目ごとの抽出率や正確さ**: 各フィールド（title、userID等）の個別性能
5. **エラー発生率**: 各抽出方法・言語のエラー発生率

#### 4.2 抽出方法別性能比較
集計結果から以下の観点で各抽出方法の性能を比較してください：

1. **@Generableマクロ vs JSON vs YAML の比較**
   - 抽出精度の違い
   - 処理時間の違い
   - エラー率の違い
   - 各フィールドの抽出成功率
   - **デタラメ抽出の発生率**（重要）

2. **日本語 vs 英語プロンプトの比較**
   - 言語による抽出精度の違い
   - 文脈理解の違い
   - エラーパターンの違い
   - **言語によるデタラメ抽出の違い**

3. **レベル別（Basic/General/Complex）の比較**
   - 複雑さによる抽出精度の変化
   - 各レベルでの最適な抽出方法
   - エラーが発生しやすいパターン
   - **複雑さによるデタラメ抽出の増加**

#### 4.3 具体的な問題点の指摘と原因考察
集計結果から以下の具体的な問題を特定し、詳細な原因考察を行ってください：

1. **デタラメ抽出の具体例と原因分析**
   - 例：title: "accoca" → 期待値: "MASTERCARD"
   - 原因：プロンプト理解の失敗、文脈の誤解釈、フィールド定義の混乱

2. **フィールド混同の具体例と原因分析**
   - 例：userIDにカード番号が抽出される
   - 原因：フィールド定義の理解不足、文脈の誤解釈

3. **形式誤解釈の具体例と原因分析**
   - 例：YAML形式でJSONが出力される
   - 原因：プロンプト指示の理解不足、形式指定の曖昧さ

4. **言語による理解の違いの具体例**
   - 日本語プロンプトでの誤抽出パターン
   - 英語プロンプトでの誤抽出パターン
   - 言語による文脈理解の違い

### 5. 最終レポートの作成

#### 5.1 集計結果の分析とレポート加筆
プログラムによる集計結果を基に、以下の作業を実施してください：

1. **エグゼクティブサマリー**
   - 実験の概要と主要な発見
   - 各抽出方法の性能比較
   - 推奨事項

2. **詳細分析セクション**
   - 抽出方法別の詳細な性能分析
   - 言語別の性能分析
   - レベル別の性能分析
   - **デタラメ抽出の詳細分析**

3. **具体的な問題点の指摘**
   - デタラメ抽出の具体例と原因分析
   - フィールド混同の具体例と原因分析
   - 形式誤解釈の具体例と原因分析
   - 言語による理解の違いの具体例

4. **エラーパターン分析**
   - 発生したエラーの詳細分析
   - エラーの原因と対策
   - 改善提案
   - **デタラメ抽出の根本原因分析**

5. **統計的分析結果**
   - 成功率の統計
   - 性能メトリクスの分析
   - 相関分析の結果
   - **デタラメ抽出の詳細統計**

6. **pending項目のAI検証結果（title、note）**
   - 各pending項目の詳細検証
   - correct/wrong判定の根拠
   - 検証結果の統計分析
   - **AI検証による精度向上の効果**
   - **完全一致項目（userID、password、url、host、port、authKey）の精度分析**

7. **推奨事項と改善提案**
   - 最適な抽出方法の選択指針
   - プロンプト改善の提案
   - システム改善の提案
   - **デタラメ抽出防止の具体的対策**
   - **pending項目の自動判定改善提案**

#### 5.2 最終レポートの完成
```bash
# 最終レポートを確認
open reports/parallel_format_experiment_report.html
```

**注意**: この作業はAI（あなた）による手動分析と加筆が必須です。プログラムによる自動生成だけでは、深い洞察や考察を含む包括的なレポートは作成できません。

## 注意事項

1. **客観性**: 分析は客観的で根拠に基づいたものにしてください
2. **具体性**: 抽象的な表現ではなく、具体的な例や数値を示してください
3. **実用性**: 改善提案は実用的で実行可能なものにしてください
4. **包括性**: すべての抽出方法・言語を網羅的に分析してください
5. **一貫性**: 分析結果は一貫性があり、矛盾のないものにしてください

## 完了基準

以下の条件をすべて満たした場合に完了とします：

1. すべての抽出方法・言語の性能が詳細に分析されている
2. エラーパターンが詳細に分析されている
3. 性能比較分析が完了している
4. 統計的分析が完了している
5. 視覚的に分かりやすい最終HTMLレポートが完成している
6. 改善提案が具体的で実用的である
7. 自動生成レポート（`reports/format_experiment_report.html`）が確認できている
8. AIによる詳細分析と最終レポート（`reports/final_format_experiment_report.html`）が完成している


## 参考ファイル

- `test_yyyymmddhhmm/`: テスト実行ディレクトリ（実行後に生成）
- `test_yyyymmddhhmm/*.json`: 構造化JSONログ（実行後に生成）
- `test_yyyymmddhhmm/*_format_experiment_report.html`: 個別HTMLレポート（実行後に生成）
- `reports/parallel_format_experiment_report.html`: 統合レポート（実行後に生成）
- `reports/final_format_experiment_report.html`: 最終レポート（AI分析・加筆後）
- `Sources/AITest/Prompts/`: プロンプトテンプレートファイル
- `Sources/AITest/AccountExtractor.swift`: 抽出方法実装
- `Sources/AITestApp/main.swift`: コンソールアプリケーション

