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
    /// 目的: 4段階の統一された抽出フローを実装
    /// 背景: プロンプト生成、テストデータ読み込み、抽出処理、メトリクス作成の統一
    /// 意図: シンプルで保守性の高い抽出フローを提供
    public func extract(
        testcase: String,
        level: Int,
        method: ExtractionMethod,
        algo: String,
        language: PromptLanguage
    ) async throws -> (AccountInfo, ExtractionMetrics, String, String?) {
        log.info("🚀 統一抽出フロー開始 - testcase: \(testcase), level: \(level), method: \(method.rawValue), algo: \(algo), language: \(language.rawValue)")
        
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
        
        return (extractionResult.accountInfo, metrics, extractionResult.rawResponse, extractionResult.requestContent)
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
