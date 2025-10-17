# @Guideマクロ改善計画書 - 2025年1月10日

## 📋 計画概要

### 目的
@Guideマクロ、@Generable、Instructions、Promptの組み合わせパターンを複数設計し、AFM（Apple Foundation Models）の抽出精度傾向を早期把握する。

### 背景
- 現在の正解率63.6%、誤り率9.1%、過剰抽出率37.5%の改善が目標
- @Guideマクロ自体は外部依存のため、我々の制御点は「説明文の質」「セッションInstructions/プロンプト」「出力検証」「失敗時処理」にある
- 初期段階では正規化スコアによる大まかな傾向把握を優先

### 制約
- 厳格な出力検証・信頼度判定・リカバリ手順は後半（TBD）
- 既存のベンチマーク仕組みを最大限活用
- 段階的アプローチ：小規模→有望案絞り込み→全量実行

## 🎯 実験パターン設計

### 命名規約
`PATTERN_{抽象/厳格/人格}-{例示/なし}-{手順1/手順2}-{ガイド短/ガイド構造}-{genOn/genOff}`

### 初回実験セット（8パターン）

| ID | パターン名 | 特徴 | 目的 |
|---|---|---|---|
| 1 | PATTERN_ABS-EX0-S1-GSHT-genOn | 抽象・短指示、例示なし、1プロンプト、@Guide短文、@Generable | 最小限の指示での基本性能 |
| 2 | PATTERN_ABS-EX1-S1-GSHT-genOn | 1)に良例×1追加 | few-shot効果の確認 |
| 3 | PATTERN_STRICT-EX0-S1-GSHT-genOn | 厳格ルール、例示なし、@Guide短文、@Generable | 制約強化の効果 |
| 4 | PATTERN_STRICT-EX1-S1-GSHT-genOn | 3)に良例×1追加 | 厳格+few-shotの相乗効果 |
| 5 | PATTERN_PERSONA-EX0-S1-GSHT-genOn | 人格（プロ秘書/アカ管）強調、例示なし、@Guide短文、@Generable | 役割活性化の効果 |
| 6 | PATTERN_PERSONA-EX1-S1-GSHT-genOn | 5)に良例×1追加 | 人格+few-shotの相乗効果 |
| 7 | PATTERN_STRICT-EX0-S2-GSHT-genOn | 2ステップ（タイプ推定→抽出）、@Guide短文、@Generable | 段階的処理の効果 |
| 8 | PATTERN_STRICT-EX0-S2-GSHT-genOff | 7)と同一指示、JSONフォーマット | @Generable vs JSON比較 |

### 文面テンプレート設計

#### 抽象（ABS）
```
以下の入力からアカウント情報を抽出してください。
- 抽出できない項目はnullを設定
- 各フィールドは1つの値のみ
```

#### 厳格（STRICT）
```
以下の入力からアカウント情報を抽出してください。

制約:
- 各フィールドは1つの値のみ設定
- 推測や創作は禁止
- 例示の転載は禁止
- 曖昧な場合はnullを設定
- 出力は一貫した形式で行う
```

#### 人格（PERSONA）
```
あなたはプロの秘書として、以下のデータからアカウント情報を抽出してください。
短時間で正確に処理することを心がけ、各フィールドは1つの値のみ設定してください。
```

#### 例示（EX1）
```
例:
入力: "GitHubアカウント: admin@example.com, パスワード: secret123"
出力: title="GitHub", userID="admin@example.com", password="secret123", url=null, note=null, host=null, port=null
```

#### ステップ（S2）
```
以下の手順でアカウント情報を抽出してください:

1. まず文書タイプを判定（ログイン情報/クレジットカード/SSH接続/その他）
2. タイプに応じて適切なフィールドを抽出
   - ログイン情報: title, userID, password, url
   - クレジットカード: title, userID（カード番号）, note（有効期限・名義）
   - SSH接続: title, userID, host, port, note
```

## 🔧 実装計画

### Phase 1: 基盤整備（Day 1）
- [ ] パターン定義定数の追加
- [ ] 切替フラグの実装
- [ ] 文面テンプレートの実装
- [ ] 小規模テスト実行

### Phase 2: 実験実行（Day 2）
- [ ] 8パターンの小規模実行
- [ ] 結果集計・分析
- [ ] 有望2-3案の選定
- [ ] 文面ブラッシュアップ

### Phase 3: 全量実行（Day 3）
- [ ] 選定パターンの全量実行
- [ ] 最終レポート生成
- [ ] 次段階計画策定

## 📊 評価指標

### 主要指標
- 正規化スコア（generate_combined_report.pyと同一ロジック）
- Precision/Recall
- 平均抽出時間（参考・評価外）
  - 備考: 処理時間はノイズが大きいため比較評価には含めない

### 分析観点
- パターン間の差の大きさ
- 軸別の効果（抽象vs厳格、例示有無、ステップ数等）

## 🎯 8パターン実験結果

### 実行結果サマリー

| パターン | 成功率 | 平均時間(参考) | フィールド数 | 特徴 |
|---------|--------|----------------|-------------|------|
| **STRICT-EX0-S1-GSHT-genOn** | **73.3%** | **1.195s** | **3.1** | ⭐ **最適** |
| PERSONA-EX0-S1-GSHT-genOn | 73.3% | 1.390s | 3.5 | 人格指示 |
| ABS-EX1-S1-GSHT-genOn | 73.3% | 1.609s | 3.0 | 抽象+例示 |
| STRICT-EX1-S1-GSHT-genOn | 53.3% | 1.132s | 2.8 | 厳格+例示 |
| PERSONA-EX1-S1-GSHT-genOn | 53.3% | 1.183s | 3.0 | 人格+例示 |
| STRICT-EX0-S2-GSHT-genOn | 53.3% | 1.106s | 2.8 | 2ステップ |
| STRICT-EX0-S2-GSHT-genOff | 53.3% | 1.106s | 2.8 | 2ステップ+JSON |
| ABS-EX0-S1-GSHT-genOn | 53.3% | 1.631s | 3.0 | 抽象指示 |

### 主要発見

1. **厳格指示が最適**: STRICT-EX0-S1-GSHT-genOnが最高性能（73.3%成功率）
2. **人格指示も同等**: PERSONA-EX0-S1-GSHT-genOnも73.3%だが処理時間が長い
3. **例示の効果限定的**: 厳格+例示パターンは逆に性能低下（53.3%）
4. **2ステップ処理の課題**: 複雑な指示でも性能向上せず（53.3%）
5. **抽象指示の限界**: 基本パターンでは複雑ケースに対応困難（53.3%）
- @Generable vs JSONの性能差

## 📁 ファイル構成

### 新規作成予定
- `Sources/AITest/PatternDefinitions.swift` - パターン定義
- `Sources/AITest/PromptTemplates.swift` - 文面テンプレート
- `docs/ai-logs/2025-01-10-pattern-experiment-results.md` - 実験結果

### 修正予定
- `Sources/AITest/AccountExtractor.swift` - パターン切替ロジック
- `Sources/AITestApp/main.swift` - パターン指定機能

## 🚀 実行開始

この計画書に基づいて、Phase 1から順次実行します。

## 📐 比較方法（正規化スコアの数値比較）

### 定義
- 正規化スコア = (正解項目数 − 誤り項目数 − 過剰項目数) / 期待項目数
- 計算は `scripts/generate_combined_report.py` の算出方法に準拠

### 比較対象パターンと採点表

| パターン | 正規化スコア | 平均抽出時間 | 備考 |
|---|---:|---:|---|
| PATTERN_ABS-EX0-S1-GSHT-genOn | TBD | TBD | 抽象・例示なし |
| PATTERN_STRICT-EX0-S1-GSHT-genOn | TBD | TBD | 厳格・例示なし |
| PATTERN_PERSONA-EX0-S1-GSHT-genOn | TBD | TBD | 人格・例示なし |
| PATTERN_STRICT-EX1-S1-GSHT-genOn | TBD | TBD | 厳格・例示あり |

手順:
1. 各パターンで `AITestApp --experiment generable_ja --pattern <PATTERN_ID>` を実行
2. 生成されたテスト出力ディレクトリ（例: `test_YYYYMMDDHHmm`）を `scripts/generate_combined_report.py` に渡して集計
3. `detailed_metrics.json` の `grouped_item_scores.by_pattern` から正規化スコアを取得
4. 上表のTBDを数値で更新

---

**作成日時**: 2025年1月10日 22:15  
**作成者**: AI Assistant  
**次回更新**: Phase 1完了時
