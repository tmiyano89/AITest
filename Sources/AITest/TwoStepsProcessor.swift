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

        /// @ai[2025-11-05 17:00] TwoSteps抽出はJSON方式のみサポート
        /// 理由: Step 1a, 1b, 2すべてをJSON方式に統一
        /// 背景: @Generableは One-step抽出でのみ使用
        guard method != .generable else {
            log.error("❌ TwoSteps抽出ではGenerable方式はサポートされていません")
            throw ExtractionError.methodNotSupported("Two-steps extraction only supports JSON method for all steps (1a, 1b, and 2)")
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // JSON方式で2層カテゴリ判定
        let contentInfo = try await analyzeDocumentTypeJSON(testData: testData, language: language)

        let step1Time = CFAbsoluteTimeGetCurrent() - startTime
        log.info("📋 推定1完了 - 処理時間: \(String(format: "%.3f", step1Time))秒, メインカテゴリ: \(contentInfo.mainCategory), サブカテゴリ: \(contentInfo.subCategory)")

        return (contentInfo, step1Time)
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

#if DEBUG
        log.info("📝 Step 1b プロンプト: \(prompt)")
#endif
        // ModelExtractorで推論実行（JSON形式）
        let extractionResult = try await modelExtractor.extract(
            from: testData,
            prompt: prompt,
            method: .json
        )

        // JSONレスポンスから subCategory を抽出
        let rawResponse = extractionResult.rawResponse

#if DEBUG
        log.info("📝 Step 1b レスポンス: \(rawResponse)")
#endif
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
    /// @ai[2025-10-27 18:30] AIレスポンスを戻り値に追加
    /// 目的: サブカテゴリに特化した構造体で情報を抽出し、AccountInfoに変換
    /// 背景: hasXXXフラグベースから、サブカテゴリ専用構造体ベースへ
    /// 意図: より精密で実用的な情報抽出を実現
    @MainActor
    func extractAccountInfoBySteps(
        testData: String,
        contentInfo: ContentInfo,
        language: PromptLanguage,
        method: ExtractionMethod
    ) async throws -> (AccountInfo, TimeInterval, String) {
        log.info("📊 推定2開始: サブカテゴリベースのアカウント情報抽出")

        /// @ai[2025-11-05 14:00] TwoSteps抽出はJSON方式のみサポート
        /// 理由: サブカテゴリ型を抽象化したため、@Generableマクロを使用できない
        /// 背景: 動的プロンプト生成により型定義が不要になった
        guard method != .generable else {
            log.error("❌ TwoSteps抽出ではGenerable方式はサポートされていません")
            throw ExtractionError.methodNotSupported("Two-steps extraction only supports JSON method. Generable method requires static type definitions which have been abstracted.")
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        let subCategory = contentInfo.subCategory
        log.info("🔍 サブカテゴリ: \(subCategory)")

        // サブカテゴリに応じた専用構造体で抽出し、AccountInfoに変換（JSON方式のみ）
        let (accountInfo, aiResponse) = try await extractAndConvertBySubCategoryJSON(
            subCategory: subCategory,
            testData: testData,
            language: language
        )

        let step2Time = CFAbsoluteTimeGetCurrent() - startTime
        log.info("📊 推定2完了 - 処理時間: \(String(format: "%.3f", step2Time))秒, title: \(accountInfo.title ?? "nil")")

        return (accountInfo, step2Time, aiResponse)
    }

    /// @ai[2025-11-05 14:00] extractAndConvertBySubCategory および extractAndConvertBySubCategoryGenerable メソッドを削除
    /// 理由: TwoSteps抽出をJSON方式のみサポートに変更
    /// 背景: サブカテゴリ型を抽象化したため、Generable方式は利用不可
    /// 変更: 直接 extractAndConvertBySubCategoryJSON を呼び出すように簡素化
    // これらのメソッドは削除されました
    // extractAccountInfoBySteps から extractAndConvertBySubCategoryJSON を直接呼び出します

    /// @ai[2025-11-05 14:00] extractToJSON メソッドを削除
    /// 理由: サブカテゴリ型を抽象化し、FoundationModelsExtractor.extractGenericJSONに統一
    /// 変更前: 25個のswitch caseで各サブカテゴリ型を個別に処理（144行）
    /// 変更後: CategoryDefinitionLoaderによる動的プロンプト生成 + 汎用JSON抽出
    /// 効果: 144行のコード削減、Single Source of Truth実現
    // extractToJSON メソッドは削除されました
    // 代わりに FoundationModelsExtractor.extractGenericJSON を使用してください

    /// サブカテゴリ抽出（JSON方式）
    /// @ai[2025-10-23 19:30] JSON方式のサブカテゴリ抽出
    /// @ai[2025-10-27 14:30] デバッグログ追加
    /// @ai[2025-10-27 18:30] AIレスポンスを戻り値に追加
    /// @ai[2025-11-05 18:00] String型に変更（enum削除）
    @MainActor
    private func extractAndConvertBySubCategoryJSON(
        subCategory: String,
        testData: String,
        language: PromptLanguage
    ) async throws -> (AccountInfo, String) {
        // CategoryDefinitionLoaderからプロンプトを取得
        let prompt = try categoryLoader.generateExtractionPrompt(
            testData: testData,
            subCategoryId: subCategory,
            language: language
        )

        log.info("📝 Step 2 プロンプト生成完了")
        log.debugLongText("🔍 プロンプト", prompt)

        // ModelExtractorで推論実行（JSON形式）
        let extractionResult = try await modelExtractor.extract(
            from: testData,
            prompt: prompt,
            method: .json
        )

        // JSONレスポンスをパース
        let rawResponse = extractionResult.rawResponse
        log.info("🤖 AI生レスポンス受信 (長さ: \(rawResponse.count)文字)")
        log.debug("📄 AIレスポンス全文:\n\(rawResponse)")

        // マークダウンコードブロックからJSONを抽出
        let jsonString = extractJSONFromMarkdown(rawResponse)
        log.debug("📝 抽出されたJSON文字列: \(jsonString)")

        // JSONを辞書に直接パース（AccountInfo構造体にデコードせず）
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            log.error("❌ JSON解析に失敗")
            log.error("📄 失敗時のレスポンス:\n\(rawResponse)")
            throw ExtractionError.invalidJSONFormat(aiResponse: rawResponse)
        }

        log.info("🔍 JSON解析成功 - フィールド数: \(json.count)")
        log.info("🔄 マッピング前のJSON: \(json)")

        // マッピングルールを適用してAccountInfoを再構築
        let converter = SubCategoryConverter()
        let mappedAccountInfo = converter.convert(from: json, subCategory: subCategory)

        log.info("✅ マッピング完了: title=\(mappedAccountInfo.title ?? "nil"), userID=\(mappedAccountInfo.userID ?? "nil"), password=\(mappedAccountInfo.password ?? "nil")")

        return (mappedAccountInfo, rawResponse)
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
