import Foundation
import FoundationModels

/// @ai[2025-10-21 13:40] 2ステップ処理器
/// 目的: 分割推定方式の実装
/// 背景: ドキュメントタイプ判定と段階的抽出による精度向上
/// 意図: より高精度で柔軟な抽出フローを提供
@available(iOS 26.0, macOS 26.0, *)
class TwoStepsProcessor {
    private let log = LogWrapper(subsystem: "com.aitest.twosteps", category: "TwoStepsProcessor")
    private let modelExtractor: ModelExtractor
    private let commonProcessor = CommonExtractionProcessor()
    private let categoryLoader = CategoryDefinitionLoader()
    private let jsonExtractor = JSONExtractor()

    init(modelExtractor: ModelExtractor) {
        self.modelExtractor = modelExtractor
        log.info("TwoStepsProcessor initialized")
    }

    /// 推定1: ドキュメントタイプ判定（2層カテゴリ判定 + 情報タイプ判定）
    /// @ai[2025-10-21 13:40] 推定1フローの実装
    /// @ai[2025-10-21 15:30] 2層カテゴリ判定に対応
    /// @ai[2025-10-23 19:30] JSON対応追加
    /// 目的: ドキュメントの内容を分析し、どのような種類の情報が含まれているかを判定
    /// 背景: 適切な抽出戦略を選択するための基準を提供
    /// 意図: 推定2の抽出戦略を決定（generable/json両方対応）
    @MainActor
    func analyzeDocumentType(
        testData: String,
        language: PromptLanguage,
        method: ExtractionMethod
    ) async throws -> (ContentInfo, TimeInterval) {
        log.info("📋 推定1開始: 2層カテゴリ判定 (method: \(method.rawValue))")
        let startTime = CFAbsoluteTimeGetCurrent()

        let contentInfo: ContentInfo

        switch method {
        case .generable:
            contentInfo = try await analyzeDocumentTypeGenerable(testData: testData, language: language)
        case .json:
            contentInfo = try await analyzeDocumentTypeJSON(testData: testData, language: language)
        case .yaml:
            throw ExtractionError.methodNotSupported("YAML method is not supported in two-steps extraction")
        }

        let step1Time = CFAbsoluteTimeGetCurrent() - startTime
        log.info("📋 推定1完了 - 処理時間: \(String(format: "%.3f", step1Time))秒, メインカテゴリ: \(contentInfo.mainCategory), サブカテゴリ: \(contentInfo.subCategory)")

        return (contentInfo, step1Time)
    }

    /// 推定1: Generable方式
    @MainActor
    private func analyzeDocumentTypeGenerable(
        testData: String,
        language: PromptLanguage
    ) async throws -> ContentInfo {
        // Step 1a: メインカテゴリ判定
        log.info("🔍 Step 1a: メインカテゴリ判定 (Generable)")
        let mainCategoryInfo = try await judgeMainCategory(testData: testData, language: language)
        log.info("✅ Step 1a完了: メインカテゴリ = \(mainCategoryInfo.mainCategory)")

        // Step 1b: サブカテゴリ判定
        log.info("🔍 Step 1b: サブカテゴリ判定 (メインカテゴリ: \(mainCategoryInfo.mainCategory))")
        let subCategoryInfo = try await judgeSubCategory(
            testData: testData,
            mainCategory: mainCategoryInfo.mainCategoryEnum,
            language: language
        )
        log.info("✅ Step 1b完了: サブカテゴリ = \(subCategoryInfo.subCategory)")

        // ContentInfo構築
        return ContentInfo(
            mainCategory: mainCategoryInfo.mainCategory,
            subCategory: subCategoryInfo.subCategory
        )
    }

    /// 推定1: JSON方式
    @MainActor
    private func analyzeDocumentTypeJSON(
        testData: String,
        language: PromptLanguage
    ) async throws -> ContentInfo {
        // Step 1a: メインカテゴリ判定
        log.info("🔍 Step 1a: メインカテゴリ判定 (JSON)")
        let mainCategory = try await judgeMainCategoryJSON(testData: testData, language: language)
        log.info("✅ Step 1a完了: メインカテゴリ = \(mainCategory)")

        // Step 1b: サブカテゴリ判定
        log.info("🔍 Step 1b: サブカテゴリ判定 (メインカテゴリ: \(mainCategory))")
        let subCategory = try await judgeSubCategoryJSON(
            testData: testData,
            mainCategory: mainCategory,
            language: language
        )
        log.info("✅ Step 1b完了: サブカテゴリ = \(subCategory)")

        // ContentInfo構築
        return ContentInfo(
            mainCategory: mainCategory,
            subCategory: subCategory
        )
    }

    /// メインカテゴリを判定
    /// @ai[2025-10-21 15:30] 2層カテゴリ判定の第1段階
    /// @ai[2025-10-24 12:15] CategoryDefinitionLoaderに統合
    @MainActor
    private func judgeMainCategory(
        testData: String,
        language: PromptLanguage
    ) async throws -> MainCategoryInfo {
        // CategoryDefinitionLoaderを使ってプロンプトを生成
        let prompt = try categoryLoader.generateMainCategoryJudgmentPrompt(
            testData: testData,
            language: language
        )

        // モデル抽出
        guard let fmExtractor = modelExtractor as? FoundationModelsExtractor else {
            throw ExtractionError.methodNotSupported("MainCategory extraction requires FoundationModelsExtractor")
        }

        let mainCategoryInfo = try await fmExtractor.extractMainCategoryInfo(from: testData, prompt: prompt)
        return mainCategoryInfo
    }

    /// サブカテゴリを判定
    /// @ai[2025-10-21 15:30] 2層カテゴリ判定の第2段階
    /// @ai[2025-10-24 12:15] CategoryDefinitionLoaderに統合
    @MainActor
    private func judgeSubCategory(
        testData: String,
        mainCategory: MainCategory,
        language: PromptLanguage
    ) async throws -> SubCategoryInfo {
        // CategoryDefinitionLoaderを使ってプロンプトを生成
        let prompt = try categoryLoader.generateSubCategoryJudgmentPrompt(
            testData: testData,
            mainCategoryId: mainCategory.rawValue,
            language: language
        )

        // モデル抽出
        guard let fmExtractor = modelExtractor as? FoundationModelsExtractor else {
            throw ExtractionError.methodNotSupported("SubCategory extraction requires FoundationModelsExtractor")
        }

        let subCategoryInfo = try await fmExtractor.extractSubCategoryInfo(from: testData, prompt: prompt)
        return subCategoryInfo
    }

    /// メインカテゴリを判定（JSON方式）
    /// @ai[2025-10-23 19:30] JSON方式のメインカテゴリ判定
    /// @ai[2025-10-24 08:50] マークダウンコードブロック対応追加
    @MainActor
    private func judgeMainCategoryJSON(
        testData: String,
        language: PromptLanguage
    ) async throws -> String {
        // CategoryDefinitionLoaderを使ってプロンプトを生成
        let prompt = try categoryLoader.generateMainCategoryJudgmentPrompt(
            testData: testData,
            language: language
        )

        // ModelExtractorで推論実行（JSON形式）
        let extractionResult = try await modelExtractor.extract(
            from: testData,
            prompt: prompt,
            method: .json
        )

        // JSONレスポンスから mainCategory を抽出
        let rawResponse = extractionResult.rawResponse

        // マークダウンコードブロックからJSONを抽出
        let jsonString = extractJSONFromMarkdown(rawResponse)

        // JSONExtractorでパース
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let mainCategory = json["mainCategory"] as? String else {
            log.error("❌ メインカテゴリのJSON解析に失敗")
            log.error("📝 レスポンス: \(rawResponse)")
            log.error("📝 抽出されたJSON: \(jsonString)")
            throw ExtractionError.invalidJSONFormat(aiResponse: rawResponse)
        }

        return mainCategory
    }

    /// サブカテゴリを判定（JSON方式）
    /// @ai[2025-10-23 19:30] JSON方式のサブカテゴリ判定
    /// @ai[2025-10-24 08:50] マークダウンコードブロック対応追加
    @MainActor
    private func judgeSubCategoryJSON(
        testData: String,
        mainCategory: String,
        language: PromptLanguage
    ) async throws -> String {
        // CategoryDefinitionLoaderを使ってプロンプトを生成
        let prompt = try categoryLoader.generateSubCategoryJudgmentPrompt(
            testData: testData,
            mainCategoryId: mainCategory,
            language: language
        )

        // ModelExtractorで推論実行（JSON形式）
        let extractionResult = try await modelExtractor.extract(
            from: testData,
            prompt: prompt,
            method: .json
        )

        // JSONレスポンスから subCategory を抽出
        let rawResponse = extractionResult.rawResponse

        // マークダウンコードブロックからJSONを抽出
        let jsonString = extractJSONFromMarkdown(rawResponse)

        // JSONExtractorでパース
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let subCategory = json["subCategory"] as? String else {
            log.error("❌ サブカテゴリのJSON解析に失敗")
            log.error("📝 レスポンス: \(rawResponse)")
            log.error("📝 抽出されたJSON: \(jsonString)")
            throw ExtractionError.invalidJSONFormat(aiResponse: rawResponse)
        }

        return subCategory
    }

    /// 推定2: サブカテゴリに基づくアカウント情報抽出
    /// @ai[2025-10-21 13:40] 推定2フローの実装
    /// @ai[2025-10-21 16:30] サブカテゴリベースのアプローチに変更
    /// @ai[2025-10-21 18:30] extractAndConvertメソッドを使用するように更新
    /// 目的: サブカテゴリに特化した構造体で情報を抽出し、AccountInfoに変換
    /// 背景: hasXXXフラグベースから、サブカテゴリ専用構造体ベースへ
    /// 意図: より精密で実用的な情報抽出を実現
    @MainActor
    func extractAccountInfoBySteps(
        testData: String,
        contentInfo: ContentInfo,
        language: PromptLanguage,
        method: ExtractionMethod
    ) async throws -> (AccountInfo, TimeInterval) {
        log.info("📊 推定2開始: サブカテゴリベースのアカウント情報抽出")
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let subCategory = contentInfo.subCategoryEnum else {
            log.error("❌ サブカテゴリが不明です")
            throw ExtractionError.invalidInput
        }

        log.info("🔍 サブカテゴリ: \(subCategory.rawValue)")

        // サブカテゴリに応じた専用構造体で抽出し、AccountInfoに変換（統合処理）
        let accountInfo = try await extractAndConvertBySubCategory(
            subCategory: subCategory,
            testData: testData,
            language: language,
            method: method
        )

        let step2Time = CFAbsoluteTimeGetCurrent() - startTime
        log.info("📊 推定2完了 - 処理時間: \(String(format: "%.3f", step2Time))秒, title: \(accountInfo.title ?? "nil")")

        return (accountInfo, step2Time)
    }

    /// サブカテゴリに応じた抽出と変換（統合処理）
    /// @ai[2025-10-21 16:30] サブカテゴリ別抽出の実装
    /// @ai[2025-10-21 17:00] 実際の抽出メソッド呼び出しに更新
    /// @ai[2025-10-21 18:30] extractAndConvertメソッドを使用するように更新
    /// @ai[2025-10-23 19:30] JSON対応追加
    /// 目的: 25種類のサブカテゴリに対応した抽出とAccountInfo変換を一度に実行
    /// 背景: @Generableマクロを活用した型安全な抽出 + SubCategoryConverterによる変換
    /// 意図: サブカテゴリごとに最適化された構造体で情報を抽出し、直接AccountInfoを取得（generable/json両方対応）
    @MainActor
    private func extractAndConvertBySubCategory(
        subCategory: SubCategory,
        testData: String,
        language: PromptLanguage,
        method: ExtractionMethod
    ) async throws -> AccountInfo {
        switch method {
        case .generable:
            return try await extractAndConvertBySubCategoryGenerable(
                subCategory: subCategory,
                testData: testData,
                language: language
            )
        case .json:
            return try await extractAndConvertBySubCategoryJSON(
                subCategory: subCategory,
                testData: testData,
                language: language
            )
        case .yaml:
            throw ExtractionError.methodNotSupported("YAML method is not supported in two-steps extraction")
        }
    }

    /// サブカテゴリ抽出（Generable方式）
    @MainActor
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

        // シンプルなプロンプトを生成（将来的にはテンプレートファイルから読み込む）
        let prompt = buildSimplePrompt(
            subCategoryName: subCategoryName,
            testData: testData,
            language: language
        )

        // @ai[2025-10-21 18:30] extractAndConvert を使用して抽出と変換を一度に実行
        // 目的: 抽出と変換の2ステップを統合
        // 背景: Generic extractAndConvert メソッドの導入
        // 意図: コードの重複を排除し、呼び出し側のコードを簡潔化
        switch subCategory {
        // Personal
        case .personalHome:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: PersonalHomeInfo.self).accountInfo
        case .personalEducation:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: PersonalEducationInfo.self).accountInfo
        case .personalHealth:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: PersonalHealthInfo.self).accountInfo
        case .personalContacts:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: PersonalContactsInfo.self).accountInfo
        case .personalOther:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: PersonalOtherInfo.self).accountInfo

        // Financial
        case .financialBanking:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: FinancialBankingInfo.self).accountInfo
        case .financialCreditCard:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: FinancialCreditCardInfo.self).accountInfo
        case .financialPayment:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: FinancialPaymentInfo.self).accountInfo
        case .financialInsurance:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: FinancialInsuranceInfo.self).accountInfo
        case .financialCrypto:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: FinancialCryptoInfo.self).accountInfo

        // Digital
        case .digitalSubscription:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: DigitalSubscriptionInfo.self).accountInfo
        case .digitalAI:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: DigitalAIInfo.self).accountInfo
        case .digitalSocial:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: DigitalSocialInfo.self).accountInfo
        case .digitalShopping:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: DigitalShoppingInfo.self).accountInfo
        case .digitalApps:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: DigitalAppsInfo.self).accountInfo

        // Work
        case .workServer:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: WorkServerInfo.self).accountInfo
        case .workSaaS:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: WorkSaaSInfo.self).accountInfo
        case .workDevelopment:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: WorkDevelopmentInfo.self).accountInfo
        case .workCommunication:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: WorkCommunicationInfo.self).accountInfo
        case .workOther:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: WorkOtherInfo.self).accountInfo

        // Infrastructure
        case .infraTelecom:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: InfraTelecomInfo.self).accountInfo
        case .infraUtilities:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: InfraUtilitiesInfo.self).accountInfo
        case .infraGovernment:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: InfraGovernmentInfo.self).accountInfo
        case .infraLicense:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: InfraLicenseInfo.self).accountInfo
        case .infraTransportation:
            return try await fmExtractor.extractAndConvert(from: testData, prompt: prompt, as: InfraTransportationInfo.self).accountInfo
        }
    }

    /// サブカテゴリ抽出（JSON方式）
    /// @ai[2025-10-23 19:30] JSON方式のサブカテゴリ抽出
    @MainActor
    private func extractAndConvertBySubCategoryJSON(
        subCategory: SubCategory,
        testData: String,
        language: PromptLanguage
    ) async throws -> AccountInfo {
        // CategoryDefinitionLoaderからプロンプトを取得
        let prompt = try categoryLoader.generateExtractionPrompt(
            testData: testData,
            subCategoryId: subCategory.rawValue,
            language: language
        )

        // ModelExtractorで推論実行（JSON形式）
        let extractionResult = try await modelExtractor.extract(
            from: testData,
            prompt: prompt,
            method: .json
        )

        // JSONレスポンスをパース
        let rawResponse = extractionResult.rawResponse
        let (accountInfoFromJSON, _) = jsonExtractor.extractFromJSONText(rawResponse)

        guard let accountInfo = accountInfoFromJSON else {
            log.error("❌ AccountInfoのJSON解析に失敗")
            throw ExtractionError.invalidJSONFormat(aiResponse: rawResponse)
        }

        // マッピングルールを適用してAccountInfoを再構築
        let converter = SubCategoryConverter()

        // JSON形式のデータを辞書に変換
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(accountInfo)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]

        // マッピングルールを適用
        let mappedAccountInfo = converter.convert(from: json, subCategory: subCategory)

        return mappedAccountInfo
    }

    /// シンプルなプロンプトを生成
    /// @ai[2025-10-21 17:00] 暫定的なプロンプト生成
    /// 目的: サブカテゴリ抽出用の基本的なプロンプトを生成
    /// 背景: 将来的にはテンプレートファイルから読み込むが、まずは動作確認用
    /// 意図: 最小限のプロンプトで抽出を実行
    private func buildSimplePrompt(
        subCategoryName: String,
        testData: String,
        language: PromptLanguage
    ) -> String {
        if language == .japanese {
            return """
            以下の文書から、\(subCategoryName)に関する情報を抽出してください。
            文書にない情報は抽出しないでください。

            【対象文書】
            \(testData)
            """
        } else {
            return """
            Extract information about \(subCategoryName) from the following document.
            Do not extract information that is not in the document.

            【Target Document】
            \(testData)
            """
        }
    }

    // MARK: - Private Methods


    /// マークダウンコードブロックからJSONを抽出
    /// @ai[2025-10-24 08:50] JSON抽出ヘルパーメソッド
    /// 目的: ```json ... ``` 形式のマークダウンコードブロックからJSONを抽出
    /// 背景: AIが説明文とJSONを両方返すため、JSONのみを抽出する必要がある
    /// 意図: JSON解析前の前処理
    private func extractJSONFromMarkdown(_ text: String) -> String {
        // パターン1: ```json ... ``` で囲まれたJSON
        let codeBlockPattern = #"```json\s*([\s\S]*?)\s*```"#
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let jsonRange = Range(match.range(at: 1), in: text) {
                    return String(text[jsonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        // パターン2: 最初の{から最後の}まで
        if let firstBrace = text.firstIndex(of: "{"),
           let lastBrace = text.lastIndex(of: "}") {
            let endIndex = lastBrace
            return String(text[firstBrace...endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // パターン3: 全体をそのまま返す
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
