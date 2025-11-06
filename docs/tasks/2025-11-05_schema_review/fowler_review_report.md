# サブカテゴリ定義スキーマ更新レビュー

**レビューワー**: ファウラー（テクニカルリード）
**日時**: 2025-11-05
**コミット**: cbdf289 "Update project configuration and enhance extraction logic"

---

## エグゼクティブサマリー

サブカテゴリ定義ファイルのスキーマを大幅に改善し、プロンプト生成を動的化する優れた設計変更が行われました。しかし、**ビルドエラーが発生し、実装が不完全**です。Generable方式のコード（FoundationModelsExtractor）が新しいスキーマに対応していません。

**判定**: ❌ **マージ不可** - 修正が必要

---

## 1. スキーマ設計の評価

### ✅ 優れた点

#### 1.1 データ駆動型プロンプト生成

**旧スキーマ**（固定プロンプト）:
```json
{
  "prompts": {
    "extraction": {
      "ja": "以下の対象文書から...",
      "en": "Extract information..."
    }
  },
  "mapping": {
    "directMapping": {...}
  }
}
```

**新スキーマ**（動的生成）:
```json
{
  "mapping": {
    "ja": [
      {
        "name": "serviceName",
        "mappingKey": "title",
        "required": true,
        "type": "string",
        "description": "サービス名"
      },
      ...
    ]
  }
}
```

**改善点**:
- ✅ **Single Source of Truth**: マッピング定義からプロンプトとスキーマを自動生成
- ✅ **保守性向上**: フィールド追加/削除時、1箇所の変更で済む
- ✅ **冗長性削除**: プロンプトテンプレートの重複が不要に
- ✅ **型安全性**: `required`, `type`フィールドで型情報を明示

**CategoryDefinitionLoader.swift:275-336** のプロンプト生成ロジックは、マッピング定義からJSONスキーマとプロンプトを動的に構築しており、非常に優れた実装です。

#### 1.2 言語別フィールド定義

```json
"mapping": {
  "ja": [...],
  "en": [...]
}
```

- ✅ 日本語と英語で異なるフィールド説明が可能
- ✅ フォールバック実装（`definition.mapping.en ?? definition.mapping.ja`）が適切

#### 1.3 note:append メカニズム

SubCategoryConverter.swift:47-58 で実装されている `note:append` は優れた設計：

```swift
if key == "note:append" {
    if let s = stringify(rawValue), !s.isEmpty {
        if let fmt = field.format, !fmt.isEmpty {
            appendedNotes.append(String(format: fmt, s))
        } else if let label = field.description, !label.isEmpty {
            appendedNotes.append("\(label): \(s)")
        }
    }
}
```

- ✅ AccountInfoの標準フィールドに直接マップできない追加情報を note に統合
- ✅ フォーマット指定が可能
- ✅ 論理的に独立した処理として実装（ファウラーの原則に合致）

---

## 2. 実装の問題点

### ❌ 致命的: ビルドエラー

**FoundationModelsExtractor.swift:327** でコンパイルエラー:

```swift
// 2. AccountInfoに変換
let converter = SubCategoryConverter()
let accountInfo = converter.convert(extracted)  // ❌ エラー
```

**エラー内容**:
1. `missing argument label 'from:' in call`
2. `missing argument for parameter 'subCategory' in call`
3. `cannot convert value of type 'T' to expected argument type '[String : Any]'`

**原因**:
- 旧シグネチャ: `convert(_ subcategoryStruct: Any) -> AccountInfo`（削除済み）
- 新シグネチャ: `convert(from json: [String: Any], subCategory: SubCategory) -> AccountInfo`

**影響範囲**: Generable方式（`@Generable`マクロ使用）が完全に動作不能

### ❌ 重大: 二重実装の問題

現状、以下の2つの異なる変換パスが存在：

#### パス1: JSON方式（✅ 動作）
```
TwoStepsProcessor.extractAndConvertBySubCategoryJSON
  → ModelExtractor.extract (JSON形式)
  → JSONを辞書にパース
  → SubCategoryConverter.convert(from: json, subCategory:)
```

#### パス2: Generable方式（❌ 壊れている）
```
TwoStepsProcessor.extractAndConvertBySubCategoryGenerable
  → FoundationModelsExtractor.extractAndConvert
  → @Generable構造体に抽出
  → SubCategoryConverter.convert(extracted)  ← ❌ 削除されたメソッド
```

**問題点**:
- ❌ **不整合**: 同じ機能（構造化データ→AccountInfo）に2つの実装
- ❌ **保守性**: スキーマ変更時、両方を更新する必要（今回失敗）
- ❌ **テスト容易性**: 2つの変換ロジックをそれぞれテストする必要

---

## 3. アーキテクチャ上の懸念

### 3.1 依存の向き

**現状の依存関係**:
```
FoundationModelsExtractor → SubCategoryConverter
TwoStepsProcessor → SubCategoryConverter
```

**問題**:
- SubCategoryConverterのシグネチャ変更がFoundationModelsExtractorに影響
- しかし、FoundationModelsExtractorは更新されていない

**推奨**:
- FoundationModelsExtractorは`@Generable`抽出に専念すべき
- AccountInfo変換は常にSubCategoryConverterに委譲
- SubCategoryConverterは`@Generable`構造体を受け取る必要はない（JSON経由で統一）

### 3.2 凝集度の問題

**FoundationModelsExtractor.extractAndConvert**（286-346行目）は2つの責務を持つ：

1. @Generableマクロを使った構造化抽出
2. SubCategoryConverterを使った変換

**問題**:
- ❌ 責務が混在（Single Responsibility Principle違反）
- ❌ Generable方式専用のロジックが散在

**推奨**:
```swift
// 抽出のみに専念
func extract<T: Generable>(from: String, prompt: String, as type: T.Type) -> T

// 変換はTwoStepsProcessorで統一
// FoundationModelsExtractor内で変換しない
```

---

## 4. 具体的な修正提案

### 修正1: FoundationModelsExtractor の extractAndConvert 削除

**理由**:
- Generable方式でも、新スキーマを使うべき
- AccountInfo変換はSubCategoryConverterに集約
- 二重実装を排除

**修正案**:
```swift
// FoundationModelsExtractor.swift

// extractAndConvert メソッドを削除

// 代わりに、TwoStepsProcessor で以下のように実装：
private func extractAndConvertBySubCategoryGenerable(...) async throws -> AccountInfo {
    // 1. @Generableで抽出
    let extracted = try await fmExtractor.extract(from: testData, prompt: prompt, as: WorkServerInfo.self)

    // 2. JSONに変換
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(extracted)
    let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]

    // 3. SubCategoryConverterで統一的に変換
    let converter = SubCategoryConverter()
    return converter.convert(from: json, subCategory: subCategory)
}
```

### 修正2: SubCategoryConverter の簡素化

**現状**:
- `convert(from: [String: Any], subCategory: SubCategory)` のみ
- `convert(_ subcategoryStruct: Any)` は削除済み（✅ 正しい）

**提案**: 現状維持で問題なし

**理由**:
- JSON形式への統一により、型安全性を保ちつつ柔軟性を確保
- Generable構造体は一旦JSONに変換してから処理（推移的な型変換）

### 修正3: プロンプト生成の厳格化

**現状の問題** (CategoryDefinitionLoader.swift:325):
```swift
制約条件：
1. `title` と `note` には必ず有効な文字列を記入してください。
```

**問題**: `title`と`note`がハードコードされている

**修正案**:
```swift
// required=true のフィールドを動的に取得
let requiredFields = fields.filter { $0.required == true }.map { $0.name }
let requiredList = requiredFields.map { "`\($0)`" }.joined(separator: ", ")

制約条件：
1. \(requiredList) には必ず有効な文字列を記入してください。
```

---

## 5. テスト実行結果

### 実行コマンド
```bash
python3 scripts/run_experiments.py --method json --mode two-steps \
  --testcases chat --algos abs --levels 1 2 3 --runs 1 --language ja \
  --output-dir test_logs/fowler_review
```

### 結果
```
❌ ビルドエラー
エラー箇所: FoundationModelsExtractor.swift:327
エラー内容: missing argument label 'from:' in call
```

**影響**:
- Generable方式が完全に使用不可
- JSON方式のみ動作する可能性がある（未確認）

---

## 6. 総合評価

### スコア

| 項目 | 評価 | コメント |
|------|------|----------|
| スキーマ設計 | ⭐⭐⭐⭐⭐ | 優れた設計。データ駆動型、保守性高い |
| 実装完全性 | ⭐☆☆☆☆ | ビルドエラー、Generable方式が壊れている |
| 依存関係 | ⭐⭐☆☆☆ | FoundationModelsExtractorの更新漏れ |
| 凝集度・結合度 | ⭐⭐⭐☆☆ | 変換ロジックが分散 |
| テスト容易性 | ⭐⭐☆☆☆ | 二重実装のため、テストが複雑 |
| **総合** | **⭐⭐☆☆☆** | スキーマは優秀だが実装が不完全 |

### 推奨アクション

#### 即座に実施すべき（優先度: 🔴 Critical）
1. ✅ FoundationModelsExtractor.extractAndConvert の削除または修正
2. ✅ TwoStepsProcessor.extractAndConvertBySubCategoryGenerable の修正
3. ✅ ビルドエラーの解消

#### 次のステップ（優先度: 🟡 High）
4. 全テストケースの実行確認（Level 1, 2, 3）
5. Generable方式とJSON方式の動作比較
6. パフォーマンステスト（変換オーバーヘッド）

#### 将来の改善（優先度: 🟢 Medium）
7. プロンプト生成の required フィールド自動検出
8. スキーマバリデーション（required フィールドの検証）
9. ドキュメント更新（スキーマ変更の説明）

---

## 7. リファクタリングの原則からの評価

### マーティン・ファウラーの視点

#### ✅ 良い点
- **Magic Number の排除**: ハードコードされたプロンプトを排除
- **Extract Method**: プロンプト生成ロジックの分離
- **Replace Conditional with Polymorphism**: 言語別処理の抽象化

#### ❌ 問題点
- **Incomplete Refactoring**: スキーマ変更が一部のコードに反映されていない
- **Shotgun Surgery**: スキーマ変更が複数のクラスに影響（修正漏れ）
- **Divergent Change**: FoundationModelsExtractorが2つの理由で変更される

**ファウラーの格言**:
> "リファクタリングの最大の敵は、不完全なリファクタリングである"

今回のケースはまさにこれに該当します。優れた設計変更ですが、すべてのコードを更新せずにコミットされています。

---

## 8. 結論

### マージ判定: ❌ **不可**

**理由**:
1. ビルドエラーが存在する
2. Generable方式が動作不能
3. テスト未実施（ログファイル0件）

### 必要な作業

**最低限（マージ前に必須）**:
1. FoundationModelsExtractor の修正
2. ビルド成功の確認
3. 基本的な動作確認（Level 1 のみでも可）

**推奨（品質保証のため）**:
1. 全レベル・全パターンでの実験実行
2. Generable方式とJSON方式の結果比較
3. リグレッションテスト

### 次のレビュー

修正完了後、以下を確認します：
- ✅ ビルドエラーの解消
- ✅ 実験実行結果（正規化スコア）
- ✅ コードの一貫性（Generable/JSON両方式の動作）

---

**レビューワー署名**: ファウラー
**日時**: 2025-11-05 12:55
