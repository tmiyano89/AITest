import Foundation

/// @ai[2025-01-19 00:30] 統一された抽出フロー
/// 目的: 新しい抽出フローを実装し、コードのシンプル化と保守性向上を実現
/// 背景: モデル抽象化と共通処理の統一
/// 意図: シンプルで拡張性の高い抽出フローを提供

/// 統一された抽出器
/// @ai[2025-01-19 00:30] 新しい抽出フローの実装
/// 目的: モデル抽象化と共通処理の統一によるシンプルな抽出フロー
/// 背景: コードの重複を排除し、保守性と拡張性を向上
/// 意図: シンプルでわかりやすい設計の実現
@available(iOS 26.0, macOS 26.0, *)
public class UnifiedExtractor {
    private let log = LogWrapper(subsystem: "com.aitest.unified", category: "UnifiedExtractor")
    private let commonProcessor = CommonExtractionProcessor()
    private let modelExtractor: ModelExtractor
    
    public init(modelExtractor: ModelExtractor) {
        self.modelExtractor = modelExtractor
        log.info("UnifiedExtractor initialized")
    }
    
    /// 新しい統一抽出フロー
    /// @ai[2025-01-19 00:30] 新しい抽出フローの実装
    /// @ai[2025-10-21 14:20] 2ステップ抽出オプション追加
    /// @ai[2025-10-22 18:30] ContentInfoを戻り値に追加
    /// @ai[2025-10-23 20:00] @MainActor追加（Swift並行処理のデータ競合エラー修正）
    /// 目的: 4段階の統一された抽出フローを実装（単純推定と分割推定を切り替え可能）
    /// 背景: プロンプト生成、テストデータ読み込み、抽出処理、メトリクス作成の統一
    /// 意図: シンプルで保守性の高い抽出フローを提供
    @MainActor
    public func extract(
        testcase: String,
        level: Int,
        method: ExtractionMethod,
        algo: String,
        language: PromptLanguage,
        useTwoSteps: Bool = false
    ) async throws -> (AccountInfo, ExtractionMetrics, String, String?, ContentInfo?) {
        log.info("🚀 統一抽出フロー開始 - testcase: \(testcase), level: \(level), method: \(method.rawValue), algo: \(algo), language: \(language.rawValue), useTwoSteps: \(useTwoSteps)")

        // 2ステップ抽出が指定されている場合は、専用のフローを使用
        if useTwoSteps {
            return try await extractByTwoSteps(
                testcase: testcase,
                level: level,
                method: method,
                algo: algo,
                language: language
            )
        }

        // 単純推定方式（既存のフロー）
        let totalStartTime = CFAbsoluteTimeGetCurrent()

        // 1. プロンプトの前段を作成（method、algo、languageのみに依存）
        let basePrompt = try commonProcessor.generatePrompt(method: method, algo: algo, language: language)
        log.debug("✅ ステップ1完了: プロンプト前段生成")

        // 2. テストデータを読み込み、プロンプトを完成させる
        let testData = try commonProcessor.loadTestData(testcase: testcase, level: level, language: language)
        let completedPrompt = commonProcessor.completePrompt(basePrompt: basePrompt, testData: testData, language: language)
        log.debug("✅ ステップ2完了: プロンプト完成")

        // 3. モデルに応じた抽出処理を実行
        let extractionResult = try await modelExtractor.extract(from: testData, prompt: completedPrompt, method: method)
        log.debug("✅ ステップ3完了: モデル抽出処理")

        // 4. メトリクスデータを作成
        let totalTime = CFAbsoluteTimeGetCurrent() - totalStartTime
        let metrics = commonProcessor.createMetrics(
            from: extractionResult.accountInfo,
            extractionTime: extractionResult.extractionTime,
            totalTime: totalTime
        )
        log.debug("✅ ステップ4完了: メトリクス作成")

        log.info("🎉 統一抽出フロー完了 - 総時間: \(String(format: "%.3f", totalTime))秒")

        // 単純推定方式の場合はContentInfoはnil
        return (extractionResult.accountInfo, metrics, extractionResult.rawResponse, extractionResult.requestContent, nil)
    }

    /// 2ステップ抽出フロー
    /// @ai[2025-10-21 14:20] 分割推定方式の実装
    /// @ai[2025-10-22 18:30] ContentInfoを戻り値に追加
    /// 目的: ドキュメントタイプ判定と段階的抽出による精度向上
    /// 背景: 単純推定では限界がある複雑なドキュメントへの対応
    /// 意図: より高精度で柔軟な抽出フローを提供
    @MainActor
    public func extractByTwoSteps(
        testcase: String,
        level: Int,
        method: ExtractionMethod,
        algo: String,
        language: PromptLanguage
    ) async throws -> (AccountInfo, ExtractionMetrics, String, String?, ContentInfo?) {
        log.info("🔀 2ステップ抽出フロー開始")

        let totalStartTime = CFAbsoluteTimeGetCurrent()

        // テストデータを読み込み
        let testData = try commonProcessor.loadTestData(testcase: testcase, level: level, language: language)
        log.debug("✅ テストデータ読み込み完了")

        // TwoStepsProcessorを初期化
        let twoStepsProcessor = TwoStepsProcessor(modelExtractor: modelExtractor)

        // 推定1: ドキュメントタイプ判定
        let (contentInfo, step1Time) = try await twoStepsProcessor.analyzeDocumentType(
            testData: testData,
            language: language,
            method: method
        )

        // 推定2: アカウント情報抽出
        let (accountInfo, step2Time, aiResponse) = try await twoStepsProcessor.extractAccountInfoBySteps(
            testData: testData,
            contentInfo: contentInfo,
            language: language,
            method: method
        )

        // メトリクスデータを作成
        let totalTime = CFAbsoluteTimeGetCurrent() - totalStartTime

        // 基本メトリクスを作成
        let baseMetrics = commonProcessor.createMetrics(
            from: accountInfo,
            extractionTime: step1Time + step2Time,
            totalTime: totalTime
        )

        // 2ステップメトリクスを作成
        // 実際に抽出されたフィールド数を使用
        let extractedInfoTypes = baseMetrics.extractedFieldsCount

        // 戦略の有効性は、抽出されたフィールド数に基づいて計算
        // 一般的なアカウント情報の平均フィールド数を5と仮定
        let strategyEffectiveness = min(1.0, Double(extractedInfoTypes) / 5.0)

        let detectedCategory = "\(contentInfo.mainCategory)/\(contentInfo.subCategory)"

        let twoStepsMetrics = TwoStepsExtractionMetrics(
            step1Time: step1Time,
            step2Time: step2Time,
            totalTime: totalTime,
            detectedCategory: detectedCategory,
            extractedInfoTypes: extractedInfoTypes,
            strategyEffectiveness: strategyEffectiveness,
            baseMetrics: baseMetrics
        )

        log.info("🎉 2ステップ抽出フロー完了 - 総時間: \(String(format: "%.3f", totalTime))秒, メインカテゴリ: \(contentInfo.mainCategory), サブカテゴリ: \(contentInfo.subCategory), 抽出フィールド数: \(extractedInfoTypes)")

        // 2ステップメトリクスをJSON文字列に変換してrawResponseとして返す
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let metricsData = try encoder.encode(twoStepsMetrics)
        let metricsJSON = String(data: metricsData, encoding: .utf8) ?? "{}"

        // 2ステップ方式の場合はContentInfoも返す（requestContentにAIレスポンスを含める）
        return (accountInfo, baseMetrics, metricsJSON, aiResponse, contentInfo)
    }
}

/// 抽出器ファクトリー
/// @ai[2025-01-19 00:30] 抽出器ファクトリーの実装
/// 目的: モデルに応じた適切な抽出器を作成
/// 背景: モデル抽象化レイヤーの実装
/// 意図: 抽出器の作成を一元化
@available(iOS 26.0, macOS 26.0, *)
public class ExtractorFactory {
    private let log = LogWrapper(subsystem: "com.aitest.factory", category: "ExtractorFactory")
    
    public init() {}
    
    /// 抽出器を作成
    /// @ai[2025-01-19 00:30] 抽出器作成の実装
    /// 目的: 外部LLM設定に応じて適切な抽出器を作成
    /// 背景: モデル抽象化レイヤーの実装
    /// 意図: 抽出器の作成を一元化
    public func createExtractor(externalLLMConfig: LLMConfig?) -> ModelExtractor {
        if let config = externalLLMConfig {
            log.info("🌐 外部LLM抽出器を作成 - URL: \(config.baseURL), Model: \(config.model)")
            return ExternalLLMExtractor(config: config)
        } else {
            log.info("🤖 FoundationModels抽出器を作成")
            return FoundationModelsExtractor()
        }
    }
}
