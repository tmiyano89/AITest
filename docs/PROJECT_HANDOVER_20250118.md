# AITest プロジェクト 作業引き継ぎ資料
**作成日**: 2025年1月18日  
**作成者**: 孔明（AI Assistant）

## 1. プロジェクトの目的と背景

### 1.1 プロジェクト概要
**AITest**は、Apple FoundationModels（AFM）の性能評価と最適化を目的とした実験環境です。特に`@Guide`マクロの改善を通じて、AIによるアカウント情報抽出の精度向上を目指しています。

### 1.2 技術的背景
- **Apple FoundationModels**: AppleのAIフレームワークを使用したアカウント情報抽出
- **@Guideマクロ**: Swiftのマクロ機能を活用したAI指示の最適化
- **@Generableマクロ**: FoundationModelsの構造化データ生成機能
- **多様な抽出パターン**: 抽象指示、厳格指示、例示あり/なし、ステップバイステップ等

### 1.3 評価指標

#### 正規化スコア（主要指標）
```
正規化スコア = (correct_items - wrong_items - unexpected_items) / expected_items
```
- **correct_items**: 正しく抽出された項目数
- **wrong_items**: 誤って抽出された項目数（間違った値）
- **unexpected_items**: 期待されていない項目数（余分な項目）
- **expected_items**: 期待される項目数（正解データ）

**特徴**: 
- 範囲: -∞ ～ 1.0（1.0が完全正解）
- 誤り項目と余分項目をペナルティとして減算
- 項目レベルでの精度を総合的に評価

#### 成功率（補助指標）
```
成功率 = correct_items / expected_items
```
- **範囲**: 0.0 ～ 1.0（1.0が完全正解）
- 正解項目のみを評価、誤り項目は考慮しない

#### 処理時間（参考値）
- **Level 1**: 1秒以内
- **Level 2**: 3秒以内  
- **Level 3**: 10秒以内
- **注意**: ノイズが大きいため評価には含めない

## 2. 現状のまとめ

### 2.1 構築済み機能

#### 実験環境の完全構築
✅ **任意のパターン指定によるテスト実行**
- コマンドライン引数による柔軟な設定
- パターン、回数、言語の個別指定可能
- 進捗表示とエラーハンドリング完備

✅ **統計レポート自動生成**
- HTML形式の詳細レポート
- 正規化スコア、成功率、処理時間の統計
- レベル別、アルゴリズム別の比較分析
- ランキング形式での性能比較

✅ **包括的な手順書（コマンドファイル）完備**
- 実験実行からpending項目検証まで全手順を網羅
- 外部LLM実験手順も含む
- 関連ファイル: [`commands/format_experiment_command.md`](commands/format_experiment_command.md)

#### アルゴリズム実装（7種類）
✅ **指示タイプ別アルゴリズム**
- `abs`: 抽象指示（最小限の指示で基本性能測定）
- `strict`: 厳格指示（制約ルールで出力品質向上）
- `persona`: 人格設定指示（プロ秘書の役割で専門知識活用）

✅ **例示有無パターン**
- `abs-ex`: 抽象指示+例示（few-shot学習効果）
- `persona-ex`: 人格設定+例示（役割+学習の相乗効果）

✅ **ステップ別アルゴリズム**
- `twosteps`: 2ステップ抽出（タイプ判定→抽出の段階的処理）

**詳細**: [`Sources/AITest/PatternDefinitions.swift`](Sources/AITest/PatternDefinitions.swift)

#### 抽出方法（3種類）
✅ **@Generableマクロ使用**
- `gen`: FoundationModelsの構造化データ生成機能を活用
- 型安全性とSwift統合の利点

✅ **JSON形式出力**
- `json`: 外部LLMとの互換性を重視
- OpenAI互換APIでの性能比較用

✅ **YAML形式出力**
- `yaml`: 人間可読性を重視した形式

#### テストケース（3レベル）
✅ **Level 1: 基本情報**
- フィールド: `title`, `note`
- 文字数: ~100文字
- 難易度: 簡単（期待精度95%以上）

✅ **Level 2: 中級情報**
- フィールド: Level 1 + `username`, `password`, `url`
- 文字数: ~300文字
- 難易度: 中程度（期待精度80-95%）

✅ **Level 3: 詳細情報**
- フィールド: Level 2 + `private_key`, `ssh_key`, `host`, `port`等
- 文字数: ~1000文字
- 難易度: 困難（期待精度60-80%）

**詳細**: 
- テストデータ設計: [`docs/TEST_DATA_DESIGN.md`](docs/TEST_DATA_DESIGN.md)
- パターン詳細: [`docs/TEST_DATA_PATTERNS.md`](docs/TEST_DATA_PATTERNS.md)
- テストデータ: [`Tests/TestData/`](Tests/TestData/)

### 2.2 完了した実験結果

#### FoundationModels性能評価（20回テスト）
**実験詳細**:
- 実験日時: 2025年10月17日 18:00
- 対象: 7アルゴリズム × 20回テスト
- 結果レポート: [`logs/202510171800_multi_experiments_report.html`](logs/202510171800_multi_experiments_report.html)

**主要発見**:
- **Level 1-2**: `strict`アルゴリズムが最高性能
- **Level 3**: 例示ありアルゴリズム（`abs-ex`, `persona-ex`）が優位
- **ハルシネーション誘導**: 低レベルでは例示による架空データ生成が問題

**統計的根拠**:
- 正規化スコアによる定量的評価
- レベル別ランキング形式での比較
- アルゴリズム特性別の性能分析

### 2.3 技術的成果

#### ログシステム統一
✅ **LogWrapperクラス実装**
- `logger`と`print`の統一インターフェース
- タイムスタンプ付きログ出力
- カテゴリ別ログレベル管理
- 関連ファイル: [`Sources/AITest/LogWrapper.swift`](Sources/AITest/LogWrapper.swift)

✅ **包括的なデバッグログとassertion実装**
- 実行フロー追跡のための`✅`マーク統一
- 外部LLM設定、JSON解析、リトライ機能のassertion
- 回帰検出のための即座エラー検知

#### 外部LLM統合
✅ **OpenAI互換API対応**
- HTTP経由での外部LLM通信
- リクエスト/レスポンスの完全ログ記録
- 関連ファイル: [`Sources/AITest/ExternalLLMClient.swift`](Sources/AITest/ExternalLLMClient.swift)

✅ **JSON解析の堅牢性向上**
- リトライ機能（最大3回、0.1秒間隔）
- エスケープ処理（改行、タブ、バックスラッシュ）
- 複数パターン対応（markdown、assistantfinal、直接JSON）

✅ **既存実験手順との完全互換性**
- ログ形式、レポート生成、pending項目検証は変更なし
- AI部分のみを置き換える設計

#### 並列実行システム
✅ **複数アルゴリズムの同時実行**
- バックグラウンド実行による時間短縮
- 関連ファイル: [`scripts/parallel_experiment_manager.py`](scripts/parallel_experiment_manager.py)

✅ **実験進捗監視機能**
- ログファイル監視による進捗確認
- 関連ファイル: [`scripts/experiment_log_monitor.py`](scripts/experiment_log_monitor.py)

✅ **中断からの再開機能**
- 既存ログファイルの検出とスキップ
- 関連ファイル: [`scripts/run_external_llm_experiment_resumable.py`](scripts/run_external_llm_experiment_resumable.py)

## 3. 今後の課題

### 3.1 即座に実行すべき課題
🎯 **外部LLM性能評価実験**
- **目的**: FoundationModelsとの客観的性能比較
- **対象**: 7種類のアルゴリズム × 20回テスト
- **外部LLM**: gpt-oss-20b（http://182.171.83.172）
- **期待成果**: 両AIの性能特性の定量的比較

### 3.2 中期的課題
📊 **@Guideマクロ最適化**
- 実験結果に基づく最適パターンの特定
- レベル別最適アルゴリズムの実装
- ハルシネーション抑制手法の開発

🔧 **システム改善**
- エラーハンドリングの更なる堅牢化
- 実験データの自動バックアップ機能
- レポート生成の自動化拡張

### 3.3 長期的課題
🚀 **新機能開発**
- 他のAIモデルとの比較実験
- リアルタイム性能監視
- 自動最適化システム

## 4. 重要なファイル構成

### 4.1 コアファイル
```
Sources/AITest/
├── AccountExtractor.swift              # メイン抽出ロジック
│   ├── extractFromText()               # 抽出メイン関数
│   ├── performExternalLLMExtraction()  # 外部LLM抽出
│   ├── parseJSONWithRetry()           # JSON解析リトライ
│   └── sanitizeJSONString()           # JSON文字列エスケープ
├── ExternalLLMClient.swift             # 外部LLM通信
│   ├── LLMConfig                       # 設定構造体
│   ├── request()                       # HTTP通信
│   └── extractAccountInfo()           # レスポンス解析
├── LogWrapper.swift                   # 統一ログシステム
│   ├── debug(), info(), warning()     # ログレベル別出力
│   └── success(), error(), fault()    # 状態別出力
└── PatternDefinitions.swift           # 実験パターン定義
    ├── ExperimentPattern              # パターン列挙型
    ├── InstructionType                # 指示タイプ分類
    └── PatternCharacteristics         # パターン特徴構造体

Sources/AITestApp/
└── main.swift                         # アプリケーションエントリーポイント
    ├── runSpecificExperiment()        # 実験実行メイン
    ├── extractExternalLLMConfigFromArguments()  # 外部LLM設定解析
    └── generateErrorStructuredLog()   # エラーログ生成
```

### 4.2 実験スクリプト
```
scripts/
├── run_experiments.py                 # 基本実験実行
│   ├── パターン指定による実験実行
│   ├── 進捗表示とエラーハンドリング
│   └── 環境変数による実行回数制御
├── run_external_llm_experiment.py    # 外部LLM実験
│   ├── OpenAI互換API対応
│   ├── タイムアウト設定（10分）
│   └── エラーログ詳細出力
├── run_external_llm_experiment_resumable.py  # 再開可能実験
│   ├── 既存ログファイル検出
│   ├── 中断箇所からの再開
│   └── 完了済み実行のスキップ
├── parallel_experiment_manager.py    # 並列実行管理
│   ├── 複数アルゴリズム同時実行
│   ├── バックグラウンドプロセス管理
│   └── シグナルハンドリング
├── experiment_log_monitor.py         # 実験進捗監視
│   ├── ログファイル監視
│   ├── 進捗パーセンテージ表示
│   └── 完了検知
├── generate_combined_report.py       # レポート生成
│   ├── 正規化スコア集計
│   ├── HTMLレポート生成
│   └── 統計分析（平均、標準偏差）
└── extract_pending_items.py          # pending項目検証
    ├── 手動検証用CSV生成
    ├── コンパクトCSV形式
    └── 自動ファイルクリーンアップ
```

### 4.3 ドキュメント
```
commands/
└── format_experiment_command.md      # 包括的手順書
    ├── 実験実行手順
    ├── 外部LLM実験手順
    ├── pending項目検証手順
    └── レポート生成手順

docs/
├── PROJECT_HANDOVER_20250118.md     # 本資料（作業引き継ぎ）
├── ARCHITECTURE.md                   # システム設計書
├── TEST_DATA_DESIGN.md              # テストデータ設計
├── TEST_DATA_PATTERNS.md            # テストデータパターン
└── IMPLEMENTATION_GUIDELINES.md     # 実装ガイドライン

Tests/TestData/                       # テストデータ
├── Chat/                            # チャットシチュエーション
│   ├── Level1_Basic.txt
│   ├── Level2_General.txt
│   └── Level3_Complex.txt
├── CreditCard/                      # クレジットカードシチュエーション
└── ...                             # その他のシチュエーション
```

### 4.4 プロンプトファイル
```
Sources/AITest/Prompts/
├── abstract_prompt.txt              # 抽象指示プロンプト
├── strict_prompt.txt                # 厳格指示プロンプト
├── persona_prompt.txt               # 人格指示プロンプト
└── json_prompt.txt                  # JSON形式プロンプト
```

## 5. 次のアクション

### 5.1 即座実行（外部LLM性能評価実験）

#### 単一アルゴリズムテスト
```bash
# 抽象指示アルゴリズムの20回テスト
python3 scripts/run_external_llm_experiment.py \
  --external-llm-url "http://182.171.83.172" \
  --external-llm-model "openai/gpt-oss-20b" \
  --patterns "chat_abs_json" \
  --runs 20 \
  --experiment-dir "test_logs/202501180800_external_llm_abs" \
  --no-report
```

#### 複数アルゴリズムテスト
```bash
# 7アルゴリズムの並列実行
python3 scripts/parallel_experiment_manager.py \
  --external-llm-url "http://182.171.83.172" \
  --external-llm-model "openai/gpt-oss-20b" \
  --algorithms "abs" "strict" "persona" "twosteps" "abs-ex" "persona-ex" "twosteps-ex" \
  --runs 20
```

#### 実験進捗監視
```bash
# 並列実行中の進捗確認
python3 scripts/monitor_experiment.py \
  --experiment-dir "test_logs/202501180800_external_llm_experiment" \
  --patterns "chat_abs_json" "chat_strict_json" "chat_persona_json" \
  --runs-per-pattern 20 \
  --generate-report
```

### 5.2 結果確認と分析

#### レポート生成
```bash
# 統合レポート生成
python3 scripts/generate_combined_report.py test_logs/202501180800_external_llm_experiment

# 結果確認
open test_logs/202501180800_external_llm_experiment/parallel_format_experiment_report.html
```

#### FoundationModelsとの比較
```bash
# FoundationModels結果との比較
open logs/202510171800_multi_experiments_report.html
```

### 5.3 期待される成果

#### 定量的比較
- **正規化スコア**: FoundationModels vs 外部LLM
- **レベル別性能**: 各レベルでの優位性
- **アルゴリズム別性能**: 指示タイプの効果比較

#### 定性的分析
- **ハルシネーション傾向**: 例示による架空データ生成の違い
- **エラーパターン**: 失敗ケースの特徴分析
- **処理時間**: レスポンス速度の比較

## 6. 重要な注意事項

### 6.1 ファイル命名規則
- **ログ形式**: `{pattern}_{algo}_{method}_{lang}_{level}_{run#}.json`
- **実験ディレクトリ**: `test_logs/yyyymmddhhmm_実験名/`
- **エラーログ**: `{pattern}_{algo}_{method}_{lang}_{level}_{run#}_error.json`

### 6.2 実験手順の注意点
- **pending項目検証**: 手動での意味的検証が必要
- **外部LLM実験**: AI部分のみ置き換え、他手順は変更なし
- **再開機能**: 中断時は`resumable`スクリプトを使用

### 6.3 トラブルシューティング
- **JSON解析エラー**: リトライ機能で自動解決
- **タイムアウト**: 10分設定、必要に応じて延長
- **ログ確認**: `LogWrapper`による詳細ログ出力

### 6.4 関連ファイル参照
- **コマンド手順**: [`commands/format_experiment_command.md`](commands/format_experiment_command.md)
- **システム設計**: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- **テストデータ**: [`docs/TEST_DATA_DESIGN.md`](docs/TEST_DATA_DESIGN.md)

---

**この資料は、プロジェクトの現状把握と今後の作業継続のために作成されました。**
**外部LLM実験により、FoundationModelsの客観的性能評価が可能になります。**
