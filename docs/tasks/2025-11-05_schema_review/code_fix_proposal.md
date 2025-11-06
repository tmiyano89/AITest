# コード修正提案

## 問題箇所と修正案

### 1. FoundationModelsExtractor.swift:320-346

#### 現状（❌ ビルドエラー）

```swift
// 旧コード - SubCategoryConverter.convert(Any) を呼び出している
public func extractAndConvert<T: Generable & Codable>(
    from testData: String,
    prompt: String,
    as contentType: T.Type
) async throws -> (content: T, accountInfo: AccountInfo) {
    log.debug("🔬 Generable抽出と変換開始 - type: \(contentType)")

    // 1. @Generableマクロで構造化抽出
    let extracted = try await extract(from: testData, prompt: prompt, as: contentType)

    // （中略：ログ出力）

    // 2. AccountInfoに変換
    let converter = SubCategoryConverter()
    let accountInfo = converter.convert(extracted)  // ❌ エラー：シグネチャ不一致

    // （中略：ログ出力）

    return (content: extracted, accountInfo: accountInfo)
}
```

**エラー内容**:
```
error: missing argument label 'from:' in call
error: missing argument for parameter 'subCategory' in call
error: cannot convert value of type 'T' to expected argument type '[String : Any]'
```

---

#### 修正案A: extractAndConvert メソッドの削除（✅ 推奨）

**理由**:
- SubCategoryConverterに変換を集約し、二重実装を排除
- TwoStepsProcessorで統一的に処理

**変更内容**:

```swift
// FoundationModelsExtractor.swift

// extractAndConvert メソッドを削除
// （286-346行目をすべて削除）
```

**呼び出し側の修正** (TwoStepsProcessor.swift):

```swift
private func extractAndConvertBySubCategoryGenerable(
    subCategory: SubCategory,
    testData: String,
    language: PromptLanguage
) async throws -> AccountInfo {
    guard let fmExtractor = modelExtractor as? FoundationModelsExtractor else {
        throw ExtractionError.methodNotSupported("Generable extraction requires FoundationModelsExtractor")
    }

    // サブカテゴリ名を取得（プロンプト生成用）
    let subCategoryName = language == .japanese ? subCategory.displayName : subCategory.rawValue

    // プロンプトを生成（暫定）
    let prompt = buildSimplePrompt(
        subCategoryName: subCategoryName,
        testData: testData,
        language: language
    )

    // 各サブカテゴリに応じて抽出
    let json: [String: Any]
    switch subCategory {
    case .workServer:
        let extracted = try await fmExtractor.extract(from: testData, prompt: prompt, as: WorkServerInfo.self)
        // Codable → JSON変換
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(extracted)
        json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]

    // （他のサブカテゴリも同様）
    // ...
    }

    // SubCategoryConverterで統一的に変換
    let converter = SubCategoryConverter()
    return converter.convert(from: json, subCategory: subCategory)
}
```

---

#### 修正案B: extractAndConvert メソッドの修正（⚠️ 非推奨）

**理由**: 二重実装が残るため、保守性が低い

**変更内容**:

```swift
public func extractAndConvert<T: Generable & Codable>(
    from testData: String,
    prompt: String,
    as contentType: T.Type,
    subCategory: SubCategory  // ← 追加
) async throws -> (content: T, accountInfo: AccountInfo) {
    log.debug("🔬 Generable抽出と変換開始 - type: \(contentType)")

    // 1. @Generableマクロで構造化抽出
    let extracted = try await extract(from: testData, prompt: prompt, as: contentType)

    // 2. JSON形式に変換
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(extracted)
    let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]

    // 3. SubCategoryConverterで変換
    let converter = SubCategoryConverter()
    let accountInfo = converter.convert(from: json, subCategory: subCategory)

    return (content: extracted, accountInfo: accountInfo)
}
```

**問題点**:
- 呼び出し側で `subCategory` を渡す必要がある
- TwoStepsProcessor の switch文（340-396行目）がさらに複雑化
- Generable → JSON → AccountInfo の推移的変換が重複

---

### 2. TwoStepsProcessor.swift の修正（修正案A採用時）

#### 現状の問題

**340-396行目**: 25種類のサブカテゴリそれぞれで `extractAndConvert` を呼び出している

```swift
switch subCategory {
case .personalHome:
    return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: PersonalHomeInfo.self).accountInfo
case .personalEducation:
    return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: PersonalEducationInfo.self).accountInfo
// ...（全25種類）
}
```

**問題**:
- 冗長（25回のほぼ同一の呼び出し）
- `extractAndConvert` の `.accountInfo` を取得しているが、`.content` は捨てられている
- サブカテゴリ構造体（PersonalHomeInfo等）の存在意義が不明確

---

#### 修正案: 統一的な処理フロー

```swift
private func extractAndConvertBySubCategoryGenerable(
    subCategory: SubCategory,
    testData: String,
    language: PromptLanguage
) async throws -> AccountInfo {
    guard let fmExtractor = modelExtractor as? FoundationModelsExtractor else {
        throw ExtractionError.methodNotSupported("Generable extraction requires FoundationModelsExtractor")
    }

    // プロンプト生成（CategoryDefinitionLoaderから取得するのが理想）
    // 暫定的には buildSimplePrompt を使用
    let subCategoryName = language == .japanese ? subCategory.displayName : subCategory.rawValue
    let prompt = buildSimplePrompt(
        subCategoryName: subCategoryName,
        testData: testData,
        language: language
    )

    // サブカテゴリに応じた型で抽出
    let json: [String: Any] = try await extractToJSON(
        fmExtractor: fmExtractor,
        testData: testData,
        prompt: prompt,
        subCategory: subCategory
    )

    // SubCategoryConverterで統一的に変換
    let converter = SubCategoryConverter()
    return converter.convert(from: json, subCategory: subCategory)
}

// ヘルパーメソッド：@Generable抽出 → JSON変換
private func extractToJSON(
    fmExtractor: FoundationModelsExtractor,
    testData: String,
    prompt: String,
    subCategory: SubCategory
) async throws -> [String: Any] {
    let encoder = JSONEncoder()

    switch subCategory {
    // Personal
    case .personalHome:
        let extracted = try await fmExtractor.extract(from: testData, prompt: prompt, as: PersonalHomeInfo.self)
        let jsonData = try encoder.encode(extracted)
        return try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]

    case .personalEducation:
        let extracted = try await fmExtractor.extract(from: testData, prompt: prompt, as: PersonalEducationInfo.self)
        let jsonData = try encoder.encode(extracted)
        return try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]

    // ...（全25種類）

    default:
        throw ExtractionError.invalidPattern("Unsupported subCategory: \(subCategory.rawValue)")
    }
}
```

**改善点**:
1. ✅ 変換ロジックが1箇所に集約（SubCategoryConverter）
2. ✅ Generable抽出とAccountInfo変換が分離
3. ✅ JSON方式との統一的なインターフェース

**残課題**:
- ⚠️ switch文の冗長性は解消されていない
- 💡 リフレクションやマクロによる動的な型解決が理想だが、Swift 6.0 の制約により困難

---

### 3. CategoryDefinitionLoader の改善（オプション）

#### 現状の問題

**325-336行目**: `title` と `note` がハードコード

```swift
制約条件：
1. `title` と `note` には必ず有効な文字列を記入してください。
```

**問題**: required フィールドが増えた場合、プロンプトを手動で更新する必要がある

---

#### 修正案: required フィールドの動的生成

```swift
public func generateExtractionPrompt(
    testData: String,
    subCategoryId: String,
    language: PromptLanguage
) throws -> String {
    let definition = try loadSubCategoryDefinition(subCategoryId: subCategoryId)

    let fields: [SubCategoryDefinition.MappingField]? = {
        switch language {
        case .japanese:
            return definition.mapping.ja
        case .english:
            return definition.mapping.en ?? definition.mapping.ja
        }
    }()

    if let fields, !fields.isEmpty {
        // JSONスキーマ生成
        let schemaLines: [String] = fields.map { field in
            let type = (field.type?.lowercased() == "integer") ? "integer" : "string"
            let isRequired = (field.required ?? false)
            if isRequired {
                return "  \"\(field.name)\": \(type),"
            } else {
                return "  \"\(field.name)\": \(type) | null,"
            }
        }

        var prettySchema = schemaLines
        if var last = prettySchema.popLast() {
            if last.hasSuffix(",") { last.removeLast() }
            prettySchema.append(last)
        }
        let schemaText = "{\n" + prettySchema.joined(separator: "\n") + "\n}"

        // ✅ required フィールドを動的に取得
        let requiredFields = fields.filter { $0.required == true }.map { $0.name }
        let requiredList = requiredFields.map { "`\($0)`" }.joined(separator: ", ")

        let subcategoryTitle: String = (language == .japanese) ? definition.name.ja : definition.name.en

        let templateJA = """
        あなたはプライベート情報管理のアシスタントです。

        添付したドキュメントから\(subcategoryTitle)に関する情報を抽出してください。

        出力は次のスキーマ構造に厳密に一致させ、**純粋なJSONオブジェクトのみ**を出力してください。

        \(schemaText)

        制約条件：
        1. \(requiredList) には必ず有効な文字列を記入してください。
        2. 他の項目は、ドキュメントに記載がなければ **null** を入れてください。
        3. 各キーの順序は上記と同じにしてください。
        4. 出力は **1個の純粋なJSONオブジェクト** のみ。改行や説明を付け加えないでください。
        5. JSON構文（括弧、カンマ、クォート）の整合性を守り、**正確な構造体としてパース可能**な状態で返してください。

        === 添付ドキュメントの内容 ===

        {TEXT}

        -------------------
        """

        // 英語版も同様に修正...

        let template = (language == .japanese) ? templateJA : templateEN
        return template.replacingOccurrences(of: "{TEXT}", with: testData)
    }

    fatalError("❌ mapping配列が見つからないか空です: subCategoryId=\(subCategoryId)")
}
```

**改善点**:
- ✅ requiredフィールドが増えても、スキーマ定義のみで対応可能
- ✅ プロンプトテンプレートの保守性向上

---

## 修正の優先順位

### Phase 1: ビルドエラー解消（最優先）

1. ✅ **FoundationModelsExtractor.extractAndConvert の削除**（修正案A）
2. ✅ **TwoStepsProcessor.extractAndConvertBySubCategoryGenerable の修正**
3. ✅ ビルド確認

**所要時間**: 30分

---

### Phase 2: 動作確認（高優先度）

4. ✅ Level 1 の実験実行（chat/abs/json/ja）
5. ✅ 結果確認（正規化スコア、AIレスポンス）

**所要時間**: 15分

---

### Phase 3: 全体テスト（中優先度）

6. ✅ Level 1, 2, 3 の全実験実行
7. ✅ Generable方式とJSON方式の比較
8. ✅ リグレッションテスト

**所要時間**: 1時間

---

### Phase 4: コード改善（低優先度）

9. 🟡 CategoryDefinitionLoader の required フィールド動的生成
10. 🟡 ドキュメント更新
11. 🟡 テストケース追加

**所要時間**: 2時間

---

## まとめ

**最低限の修正** (Phase 1 + 2):
- FoundationModelsExtractor の extractAndConvert 削除
- TwoStepsProcessor の修正
- Level 1 の動作確認

**これにより**:
- ✅ ビルドエラー解消
- ✅ 基本機能の動作確認
- ✅ マージ可能な状態

**将来の改善**:
- required フィールドの動的生成
- switch文の冗長性削減（リフレクション等）
- パフォーマンス最適化
