# AIコマンド: FoundationModels 基礎実験

## 概要
FoundationModelsの性能評価結果を基に、AIが手動で分析・編集を行い、包括的なレポートを作成するための指示書です。

## 前提条件
- ベンチマーク実行が完了していること
- `benchmark_report.html`が生成されていること
- 各テストケースの詳細な結果データが利用可能であること

## 作業手順

### 1. ベンチマーク結果の確認
```bash
# 最新のベンチマーク結果を確認（コンソール出力をログファイルに保存）
swift run AITestApp > benchmark_execution.log 2>&1

# ログファイルの内容を確認
cat benchmark_execution.log

# 生成されたHTMLレポートを確認
open reports/benchmark_report.html
```

#### 1.1 ログファイルの場所
- **ログファイル**: `benchmark_execution.log`
- **HTMLレポート**: `reports/benchmark_report.html`

### 2. 各テストケースのAI回答を詳細分析

#### 2.1 単一テストデバッグモードでAI回答を確認
```bash
# 各テストケースのAI回答を個別に確認
swift run AITestApp --debug-single
```

#### 2.2 ベンチマーク実行ログの確認
以下のコマンドを実行し、コンソール出力から各テストケースの成功率を確認してください：

```bash
# ベンチマーク実行（コンソール出力をログファイルに保存）
swift run AITestApp > benchmark_execution.log 2>&1

# ログファイルの内容を確認
cat benchmark_execution.log
```

#### 2.3 ログから確認すべき情報
ログファイルから以下の情報を抽出し、各テストケースの成功率を記録してください：

1. **Chat Level 1 (Basic)** - ログから成功率を確認
2. **Chat Level 2 (General)** - ログから成功率を確認
3. **Chat Level 3 (Complex)** - ログから成功率を確認
4. **Contract Level 1 (Basic)** - ログから成功率を確認
5. **Contract Level 2 (General)** - ログから成功率を確認
6. **Contract Level 3 (Complex)** - ログから成功率を確認
7. **Credit Card Level 1 (Basic)** - ログから成功率を確認
8. **Credit Card Level 2 (General)** - ログから成功率を確認
9. **Credit Card Level 3 (Complex)** - ログから成功率を確認
10. **Voice Recognition Level 1 (Basic)** - ログから成功率を確認
11. **Voice Recognition Level 2 (General)** - ログから成功率を確認
12. **Voice Recognition Level 3 (Complex)** - ログから成功率を確認
13. **Password Manager Level 1 (Basic)** - ログから成功率を確認
14. **Password Manager Level 2 (General)** - ログから成功率を確認
15. **Password Manager Level 3 (Complex)** - ログから成功率を確認

#### 2.4 ログ分析のポイント
ログから以下の情報を抽出してください：

- **成功率**: 各テストケースの成功率（例：`成功率: 100.0%`）
- **平均抽出時間**: 各テストケースの平均抽出時間
- **平均信頼度**: 各テストケースの平均信頼度
- **項目別成功率**: 各フィールドの成功率
- **文字レベル精度**: 各フィールドの文字レベル精度
- **note内容分析**: note内容の多様性スコアと最頻出内容
- **AI回答分析**: AI回答の分析結果と所感

### 3. note内容の詳細分析

#### 3.1 各テストケースのnote内容を確認
以下のファイルを確認し、AIが抽出したnote内容を分析してください：

- `Tests/TestData/Chat/Level1_Basic.txt`
- `Tests/TestData/Chat/Level2_General.txt`
- `Tests/TestData/Chat/Level3_Complex.txt`
- `Tests/TestData/Contract/Level1_Basic.txt`
- `Tests/TestData/Contract/Level2_General.txt`
- `Tests/TestData/Contract/Level3_Complex.txt`
- `Tests/TestData/CreditCard/Level1_Basic.txt`
- `Tests/TestData/CreditCard/Level2_General.txt`
- `Tests/TestData/CreditCard/Level3_Complex.txt`
- `Tests/TestData/VoiceRecognition/Level1_Basic.txt`
- `Tests/TestData/VoiceRecognition/Level2_General.txt`
- `Tests/TestData/VoiceRecognition/Level3_Complex.txt`
- `Tests/TestData/PasswordManager/Level1_Basic.txt`
- `Tests/TestData/PasswordManager/Level2_General.txt`
- `Tests/TestData/PasswordManager/Level3_Complex.txt`

#### 3.2 note内容の評価基準
各テストケースのnote内容について、以下の観点で評価してください：

1. **内容の適切性**: テストケースの文脈に適した内容か
2. **情報の有用性**: アカウント管理に役立つ情報が含まれているか
3. **一貫性**: 同じテストケース内で一貫した内容が抽出されているか
4. **詳細度**: 必要な詳細情報が適切に含まれているか
5. **誤解釈**: AIが文脈を誤解釈していないか

### 4. AI回答の所感分析

#### 4.1 各テストケースのAI回答パターンを分析
以下の観点で、各テストケースのAI回答を分析してください：

1. **抽出精度**: どのフィールドが正確に抽出されているか
2. **一貫性**: 同じテストケース内で一貫した結果が得られているか
3. **エラーパターン**: どのようなエラーが頻発しているか
4. **理解度**: AIがテストケースの文脈を正しく理解しているか
5. **改善点**: どの部分の改善が必要か

#### 4.2 成功パターンの特定
成功率が高いテストケース（80%以上）について：

1. **成功要因**: なぜ成功しているのか
2. **共通点**: 成功しているテストケースの共通点
3. **再現性**: 成功パターンを他のテストケースに適用できるか

#### 4.3 失敗パターンの特定
成功率が低いテストケース（50%未満）について：

1. **失敗要因**: なぜ失敗しているのか
2. **共通点**: 失敗しているテストケースの共通点
3. **改善策**: 具体的な改善方法

### 5. 文字レベル精度の詳細分析

#### 5.1 期待値との比較
各フィールドの文字レベル精度について：

1. **完全一致**: 100%精度のフィールド
2. **部分一致**: 50-99%精度のフィールド
3. **低精度**: 50%未満のフィールド
4. **誤抽出**: 全く異なる値が抽出されたフィールド

#### 5.2 文字レベルのエラーパターン
以下のエラーパターンを特定してください：

1. **スペースの処理**: スペースの有無による違い
2. **大文字小文字**: 大文字小文字の違い
3. **数字の誤認識**: 0とO、1とlなどの混同
4. **記号の処理**: 特殊記号の処理方法
5. **文字の追加・削除**: 余分な文字の追加や必要な文字の削除

### 6. HTMLレポートの修正・加筆

#### 6.1 既存HTMLレポートの確認
まず、既存のHTMLレポートの内容を確認してください：

```bash
# HTMLレポートの内容を確認
open reports/benchmark_report.html
```

#### 6.2 HTMLレポートの修正・加筆内容
既存の`benchmark_report.html`を基に、以下の内容を追加・修正してください：

1. **エグゼクティブサマリーセクションの追加**
   - 全体の性能評価と主要な発見
   - 成功率の分布と傾向
   - 主要な問題点と改善点

2. **note内容評価セクションの追加**
   - 各テストケースのnote内容の質的評価
   - 内容の適切性、有用性、一貫性の分析
   - 具体的なnote内容の例と評価

3. **AI回答所感セクションの追加**
   - 各テストケースのAI回答の詳細な所感
   - 成功パターンと失敗パターンの分析
   - AIの理解度と改善点の評価

4. **文字レベル精度分析セクションの追加**
   - 期待値との詳細な比較分析
   - 文字レベルのエラーパターン分析
   - 精度向上のための具体的な提案

5. **改善提案セクションの追加**
   - 具体的な改善方法と推奨事項
   - テストケースの改善提案
   - AIプロンプトの改善提案

6. **視覚的改善**
   - チャートやグラフの追加
   - 色分けによる成功率の可視化
   - 重要な情報のハイライト

#### 6.3 修正・加筆手順
1. **既存HTMLファイルのコピー作成**
   ```bash
   cp reports/benchmark_report.html reports/enhanced_benchmark_report.html
   ```

2. **HTMLファイルの直接編集**
   - 既存のHTMLファイルをテキストエディタで開く
   - 上記の内容を適切な場所に追加
   - CSSスタイルの調整
   - 視覚的要素の追加

3. **最終レポートの完成**
   - 修正・加筆されたHTMLレポートを`reports/final_benchmark_report.html`として保存
   - ブラウザで表示確認
   - 必要に応じて追加修正

### 7. 追加の分析

#### 7.1 統計的分析
以下の統計的分析を実施してください：

1. **成功率の分布**: 各レベル（Basic/General/Complex）での成功率
2. **フィールド別成功率**: 各フィールドの成功率の比較
3. **文字レベル精度の分布**: 文字レベル精度の分布状況
4. **処理時間の分析**: 抽出時間と成功率の相関関係

#### 7.2 比較分析
以下の比較分析を実施してください：

1. **レベル間比較**: Basic/General/Complexの比較
2. **シチュエーション間比較**: Chat/Contract/CreditCard/VoiceRecognition/PasswordManagerの比較
3. **フィールド間比較**: 各フィールドの抽出難易度の比較

### 8. 最終レポートの完成

#### 8.1 最終HTMLレポートの作成
修正・加筆されたHTMLレポートを最終版として完成させてください：

1. **レポートファイル名**: `reports/final_benchmark_report.html`
2. **内容**: 上記の分析結果をすべて統合
3. **視覚的改善**: チャート、グラフ、色分けによる可視化
4. **ナビゲーション**: 目次とリンクによる操作性向上
5. **レスポンシブデザイン**: 様々な画面サイズに対応

#### 8.2 最終レポートの確認
以下の観点で最終レポートを確認してください：

1. **内容の完全性**: すべての分析結果が含まれているか
2. **視覚的な分かりやすさ**: 情報が整理されて見やすいか
3. **技術的正確性**: データと分析が正確か
4. **実用性**: 改善提案が具体的で実行可能か
5. **一貫性**: 全体を通して一貫した品質か

## 注意事項

1. **客観性**: 分析は客観的で根拠に基づいたものにしてください
2. **具体性**: 抽象的な表現ではなく、具体的な例や数値を示してください
3. **実用性**: 改善提案は実用的で実行可能なものにしてください
4. **包括性**: すべてのテストケースとフィールドを網羅的に分析してください
5. **一貫性**: 分析結果は一貫性があり、矛盾のないものにしてください

## 完了基準

以下の条件をすべて満たした場合に完了とします：

1. すべてのテストケースのAI回答が詳細に分析されている
2. すべてのnote内容が質的に評価されている
3. 文字レベル精度の詳細分析が完了している
4. 統計的分析と比較分析が完了している
5. 既存のHTMLレポートが修正・加筆されている
6. 視覚的に分かりやすい最終HTMLレポートが完成している
7. 改善提案が具体的で実用的である
8. 最終レポート（`reports/final_benchmark_report.html`）が完成している

## 実行コマンド

```bash
# ベンチマーク実行（ログファイルに保存）
swift run AITestApp > benchmark_execution.log 2>&1

# ログファイルの内容を確認
cat benchmark_execution.log

# 単一テストデバッグ
swift run AITestApp --debug-single

# HTMLレポート確認
open reports/benchmark_report.html
```

## 参考ファイル

- `benchmark_execution.log`: ベンチマーク実行ログ（実行後に生成）
- `reports/benchmark_report.html`: 自動生成されたHTMLレポート
- `Tests/TestData/`: 各テストケースのデータファイル
- `Sources/AITest/`: ベンチマーク実行プログラム
- `Sources/AITestApp/main.swift`: コンソールアプリケーション

このコマンドファイルに従って、FoundationModelsの性能評価レポートを作成してください。
