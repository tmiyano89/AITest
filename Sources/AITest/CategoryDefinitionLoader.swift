import Foundation

/// @ai[2025-10-23 19:00] カテゴリ定義ローダー
/// 目的: category_definitions.jsonを読み込み、カテゴリ判定用のプロンプトを提供
/// 背景: JSON対応の2ステップ抽出を実現
/// 意図: 柔軟で拡張性の高いカテゴリ定義管理

@available(iOS 26.0, macOS 26.0, *)
public struct CategoryDefinition: Codable, Sendable {
    public let version: String
    public let description: String
    public let mainCategories: [MainCategoryDef]
    public let prompts: CategoryPrompts

    public struct MainCategoryDef: Codable, Sendable {
        public let id: String
        public let name: LocalizedString
        public let description: LocalizedString
        public let examples: LocalizedStringArray
        public let subcategories: [String]
    }

    public struct LocalizedString: Codable, Sendable {
        public let ja: String
        public let en: String
    }

    public struct LocalizedStringArray: Codable, Sendable {
        public let ja: [String]
        public let en: [String]
    }

    public struct CategoryPrompts: Codable, Sendable {
        public let mainCategoryJudgment: LocalizedString
        public let subCategoryJudgment: LocalizedString
    }
}

@available(iOS 26.0, macOS 26.0, *)
public struct SubCategoryDefinition: Codable, Sendable {
    public let id: String
    public let name: CategoryDefinition.LocalizedString
    public let description: CategoryDefinition.LocalizedString
    public let examples: CategoryDefinition.LocalizedStringArray
    public let mapping: MappingDefinition

    public struct MappingDefinition: Codable, Sendable {
        // Array-based mapping definition (localized)
        public let ja: [MappingField]?
        public let en: [MappingField]?
    }

    public struct MappingField: Codable, Sendable {
        public let name: String
        public let description: String?
        public let required: Bool?
        public let mappingKey: String?
        public let format: String?
        public let type: String? // "string" (default) or "integer"
    }
}

/// @ai[2025-10-23 19:00] カテゴリ定義ローダー
/// 目的: カテゴリ定義ファイルを読み込み、プロンプト生成をサポート
/// 背景: JSON対応の2ステップ抽出を実現
/// 意図: ファイルベースの柔軟な定義管理
@available(iOS 26.0, macOS 26.0, *)
public class CategoryDefinitionLoader {
    private let log = LogWrapper(subsystem: "com.aitest.loader", category: "CategoryDefinitionLoader")
    private var categoryDefinition: CategoryDefinition?
    private var subcategoryDefinitions: [String: SubCategoryDefinition] = [:]

    public init() {
        log.info("CategoryDefinitionLoader initialized")
    }

    /// カテゴリ定義ファイルを読み込み
    /// @ai[2025-10-24 12:30] fatalError追加（必須リソースの欠落を即座に検出）
    public func loadCategoryDefinition() throws -> CategoryDefinition {
        if let cached = categoryDefinition {
            return cached
        }

        log.debug("📂 カテゴリ定義ファイルを読み込み中...")

        let fileName = "category_definitions.json"

        // Try with subdirectory first
        var resourceURL = Bundle.module.url(
            forResource: fileName,
            withExtension: nil,
            subdirectory: "CategoryDefinitions"
        )

        // If not found, try without subdirectory
        if resourceURL == nil {
            resourceURL = Bundle.module.url(forResource: fileName, withExtension: nil)
        }

        guard let resourceURL = resourceURL else {
            log.error("❌ カテゴリ定義ファイルが見つかりません: \(fileName)")
            log.error("❌ Bundle.module.resourceURL: \(String(describing: Bundle.module.resourceURL))")
            log.error("❌ Bundle.module.bundlePath: \(Bundle.module.bundlePath)")
            fatalError("❌ 必須のカテゴリ定義ファイルが見つかりません: \(fileName)\nパス: CategoryDefinitions/\(fileName)\nプロジェクトのビルド設定とリソース配置を確認してください。")
        }

        do {
            let data = try Data(contentsOf: resourceURL)
            let decoder = JSONDecoder()
            let definition = try decoder.decode(CategoryDefinition.self, from: data)

            categoryDefinition = definition
            log.info("✅ カテゴリ定義ファイル読み込み完了")

            return definition
        } catch {
            log.error("❌ カテゴリ定義ファイルのデコードに失敗: \(error)")
            fatalError("❌ カテゴリ定義ファイルのデコードに失敗: \(fileName)\nエラー: \(error)\nファイルの内容とフォーマットを確認してください。")
        }
    }

    /// サブカテゴリ定義ファイルを読み込み
    /// @ai[2025-10-24 12:30] fatalError追加（必須リソースの欠落を即座に検出）
    public func loadSubCategoryDefinition(subCategoryId: String) throws -> SubCategoryDefinition {
        if let cached = subcategoryDefinitions[subCategoryId] {
            return cached
        }

        log.debug("📂 サブカテゴリ定義ファイルを読み込み中: \(subCategoryId)")

        let fileName = "\(subCategoryId).json"

        // Try with subdirectory first
        var resourceURL = Bundle.module.url(
            forResource: fileName,
            withExtension: nil,
            subdirectory: "CategoryDefinitions/subcategories"
        )

        // If not found, try without subdirectory
        if resourceURL == nil {
            resourceURL = Bundle.module.url(forResource: fileName, withExtension: nil)
        }

        guard let resourceURL = resourceURL else {
            log.error("❌ サブカテゴリ定義ファイルが見つかりません: \(fileName)")
            log.error("❌ Bundle.module.resourceURL: \(String(describing: Bundle.module.resourceURL))")
            log.error("❌ Bundle.module.bundlePath: \(Bundle.module.bundlePath)")
            fatalError("❌ 必須のサブカテゴリ定義ファイルが見つかりません: \(fileName)\nサブカテゴリID: \(subCategoryId)\nパス: CategoryDefinitions/subcategories/\(fileName)\nプロジェクトのビルド設定とリソース配置を確認してください。")
        }

        do {
            let data = try Data(contentsOf: resourceURL)
            let decoder = JSONDecoder()
            let definition = try decoder.decode(SubCategoryDefinition.self, from: data)

            subcategoryDefinitions[subCategoryId] = definition
            log.info("✅ サブカテゴリ定義ファイル読み込み完了: \(subCategoryId)")

            return definition
        } catch {
            log.error("❌ サブカテゴリ定義ファイルのデコードに失敗: \(error)")
            fatalError("❌ サブカテゴリ定義ファイルのデコードに失敗: \(fileName)\nサブカテゴリID: \(subCategoryId)\nエラー: \(error)\nファイルの内容とフォーマットを確認してください。")
        }
    }

    /// メインカテゴリに属するサブカテゴリIDのリストを取得
    /// @ai[2025-11-06 18:00] category_definitions.jsonから動的に取得
    public func getSubCategoryIds(forMainCategory mainCategoryId: String) throws -> [String] {
        log.debug("🔍 サブカテゴリIDリストを取得中: \(mainCategoryId)")

        let definition = try loadCategoryDefinition()

        guard let mainCategory = definition.mainCategories.first(where: { $0.id == mainCategoryId }) else {
            log.error("❌ メインカテゴリが見つかりません: \(mainCategoryId)")
            throw ExtractionError.invalidInput
        }

        log.debug("✅ サブカテゴリIDリスト取得完了: \(mainCategory.subcategories.count)件")
        return mainCategory.subcategories
    }

    /// 全サブカテゴリIDを取得
    /// @ai[2025-11-06 18:00] category_definitions.jsonから動的に取得（ハードコード削除）
    private func getAllSubCategoryIds() throws -> [String] {
        let definition = try loadCategoryDefinition()
        let allIds = definition.mainCategories.flatMap { $0.subcategories }
        log.debug("✅ 全サブカテゴリID取得完了: \(allIds.count)件")
        return allIds
    }

    /// メインカテゴリ判定プロンプトを生成
    public func generateMainCategoryJudgmentPrompt(
        testData: String,
        language: PromptLanguage
    ) throws -> String {
        let definition = try loadCategoryDefinition()

        // メインカテゴリ定義を整形
        let categoryDefinitions = definition.mainCategories.enumerated().map { (index, category) in
            let number = index + 1
            let name = language == .japanese ? category.name.ja : category.name.en
            let desc = language == .japanese ? category.description.ja : category.description.en
            let examples = language == .japanese ? category.examples.ja : category.examples.en
            let examplesText = examples.map { "   - \($0)" }.joined(separator: "\n")

            return """
            \(number). **\(category.id)（\(name)）**
               \(desc)
               例:
            \(examplesText)
            """
        }.joined(separator: "\n\n")

        // プロンプトテンプレートを取得
        let template = language == .japanese
            ? definition.prompts.mainCategoryJudgment.ja
            : definition.prompts.mainCategoryJudgment.en

        // プレースホルダーを置換
        let prompt = template
            .replacingOccurrences(of: "{MAIN_CATEGORY_DEFINITIONS}", with: categoryDefinitions)
            .replacingOccurrences(of: "{TEXT}", with: testData)

        return prompt
    }

    /// サブカテゴリ判定プロンプトを生成
    public func generateSubCategoryJudgmentPrompt(
        testData: String,
        mainCategoryId: String,
        language: PromptLanguage
    ) throws -> String {
        let definition = try loadCategoryDefinition()
        let subcategoryIds = try getSubCategoryIds(forMainCategory: mainCategoryId)

        // サブカテゴリ定義を整形
        let subcategoryDefinitions = subcategoryIds.enumerated().map { (index, subcategoryId) -> String in
            guard let subCategoryDef = try? loadSubCategoryDefinition(subCategoryId: subcategoryId) else {
                return ""
            }

            let number = index + 1
            let name = language == .japanese ? subCategoryDef.name.ja : subCategoryDef.name.en
            let desc = language == .japanese ? subCategoryDef.description.ja : subCategoryDef.description.en
            let examples = language == .japanese ? subCategoryDef.examples.ja : subCategoryDef.examples.en
            let examplesText = examples.isEmpty ? "" : "\n   例: " + examples.joined(separator: ", ")

            return """
            \(number). **\(subcategoryId)（\(name)）**
               \(desc)\(examplesText)
            """
        }.joined(separator: "\n\n")

        // メインカテゴリ名を取得
        let mainCategory = definition.mainCategories.first { $0.id == mainCategoryId }
        let mainCategoryName = language == .japanese
            ? mainCategory?.name.ja ?? mainCategoryId
            : mainCategory?.name.en ?? mainCategoryId

        // プロンプトテンプレートを取得
        let template = language == .japanese
            ? definition.prompts.subCategoryJudgment.ja
            : definition.prompts.subCategoryJudgment.en

        // プレースホルダーを置換
        let prompt = template
            .replacingOccurrences(of: "{MAIN_CATEGORY_NAME}", with: mainCategoryName)
            .replacingOccurrences(of: "{SUB_CATEGORY_COUNT}", with: "\(subcategoryIds.count)")
            .replacingOccurrences(of: "{SUB_CATEGORY_DEFINITIONS}", with: subcategoryDefinitions)
            .replacingOccurrences(of: "{TEXT}", with: testData)

        return prompt
    }

    /// サブカテゴリ抽出プロンプトを生成
    public func generateExtractionPrompt(
        testData: String,
        subCategoryId: String,
        language: PromptLanguage
    ) throws -> String {
        let definition = try loadSubCategoryDefinition(subCategoryId: subCategoryId)

        // If new mapping array exists, build from template dynamically
        let fields: [SubCategoryDefinition.MappingField]? = {
            switch language {
            case .japanese:
                return definition.mapping.ja
            case .english:
                return definition.mapping.en ?? definition.mapping.ja
            }
        }()

        if let fields, !fields.isEmpty {
            // Build JSON schema lines according to mapping fields order
            let schemaLines: [String] = fields.map { field in
                let type = (field.type?.lowercased() == "integer") ? "integer" : "string"
                let isRequired = (field.required ?? false)
                if isRequired {
                    return "  \"\(field.name)\": \(type),"
                } else {
                    return "  \"\(field.name)\": \(type) | null,"
                }
            }

            // Remove trailing comma on last line for a pretty schema
            var prettySchema = schemaLines
            if var last = prettySchema.popLast() {
                if last.hasSuffix(",") { last.removeLast() }
                prettySchema.append(last)
            }
            let schemaText = "{\n" + prettySchema.joined(separator: "\n") + "\n}"

            // Build template text
            let subcategoryTitle: String = (language == .japanese) ? definition.name.ja : definition.name.en

            let templateJA = """
            あなたはプライベート情報管理のアシスタントです。

            添付したドキュメントから\(subcategoryTitle)に関する情報を抽出してください。

            出力は次のスキーマ構造に厳密に一致させ、**純粋なJSONオブジェクトのみ**を出力してください。

            \(schemaText)

            制約条件：
            1. `title` と `note` には必ず有効な文字列を記入してください。
            2. 他の項目は、ドキュメントに記載がなければ **null** を入れてください。
            3. 各キーの順序は上記と同じにしてください。
            4. 出力は **1個の純粋なJSONオブジェクト** のみ。改行や説明を付け加えないでください。
            5. JSON構文（括弧、カンマ、クォート）の整合性を守り、**正確な構造体としてパース可能**な状態で返してください。

            === 添付ドキュメントの内容 ===

            {TEXT}

            -------------------
            """

            let templateEN = """
            You are an assistant for private information management.

            Extract information about \(subcategoryTitle) from the attached document.

            Output must strictly match the following schema and return a **pure JSON object only**.

            \(schemaText)

            Constraints:
            1. Provide valid strings for `title` and `note`.
            2. For other fields, put **null** if not present in the document.
            3. Keep the keys in the exact same order as above.
            4. Return **exactly one pure JSON object**. Do not add line breaks or explanations.
            5. Ensure valid JSON syntax (braces, commas, quotes) so it is precisely parseable.

            === Attached Document ===

            {TEXT}

            -------------------
            """

            let template = (language == .japanese) ? templateJA : templateEN
            return template.replacingOccurrences(of: "{TEXT}", with: testData)
        }

        fatalError("❌ mapping配列が見つからないか空です: subCategoryId=\(subCategoryId)")
    }
}
