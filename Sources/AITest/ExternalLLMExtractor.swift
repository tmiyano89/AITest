import Foundation

/// @ai[2025-01-19 00:30] 外部LLM用抽出器
/// 目的: 外部LLMを使用した抽出処理を実装
/// 背景: Generableは未対応、JSONメソッドのみ対応
/// 意図: 外部LLM固有の処理を抽象化

/// 外部LLM用の抽出器
/// @ai[2025-01-19 00:30] 外部LLM抽出の実装
/// 目的: 外部LLMを使用した抽出処理を提供
/// 背景: Generableは未対応、JSONメソッドのみ対応
/// 意図: 外部LLM固有の処理を実装
@available(iOS 26.0, macOS 26.0, *)
public class ExternalLLMExtractor: ModelExtractor {
    private let log = LogWrapper(subsystem: "com.aitest.llm", category: "ExternalLLMExtractor")
    private let jsonExtractor = JSONExtractor()
    private let client: ExternalLLMClient
    
    public init(config: LLMConfig) {
        self.client = ExternalLLMClient(config: config)
        log.info("ExternalLLMExtractor initialized - URL: \(config.baseURL), Model: \(config.model)")
    }
    
    /// テキストからアカウント情報を抽出
    /// @ai[2025-01-19 00:30] 外部LLM抽出の実装
    /// 目的: Generableは未対応、JSONメソッドのみ対応
    /// 背景: モデル抽象化レイヤーの実装
    /// 意図: 外部LLM固有の処理を実装
    @MainActor
    public func extract(from text: String, prompt: String, method: ExtractionMethod) async throws -> ExtractionResult {
        log.info("🌐 外部LLM抽出開始 - method: \(method.rawValue)")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 抽出方法に応じた処理を実行
        let accountInfo: AccountInfo
        let rawResponse: String
        let requestContent: String
        
        switch method {
        case .generable:
            fatalError("Generable method is not supported for external LLM")
        case .json:
            (accountInfo, rawResponse, requestContent) = try await performJSONExtraction(prompt: prompt)
        }
        
        let extractionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        log.info("✅ 外部LLM抽出完了 - 時間: \(String(format: "%.3f", extractionTime))秒")
        
        return ExtractionResult(
            accountInfo: accountInfo,
            rawResponse: rawResponse,
            requestContent: requestContent,
            extractionTime: extractionTime,
            method: method
        )
    }
    
    /// JSON抽出を実行
    /// @ai[2025-01-19 00:30] 外部LLM JSON抽出の実装
    /// 目的: 外部LLMからのJSONレスポンスを処理
    /// 背景: 統一されたJSON抽出処理を使用
    /// 意図: JSON抽出の一元化
    @MainActor
    private func performJSONExtraction(prompt: String) async throws -> (AccountInfo, String, String) {
        log.debug("🔍 外部LLM JSON抽出開始")
        
        // 外部LLMクライアントを使用してレスポンスを取得
        let client = self.client
        let (content, rawResponse, requestContent, _, error) = await client.extractAccountInfo(from: prompt, prompt: prompt)
        
        // エラーチェック
        if let error = error {
            log.error("❌ 外部LLM通信エラー: \(error.localizedDescription)")
            throw error
        }
        
        guard let content = content, let rawResponse = rawResponse else {
            log.error("❌ 外部LLMからレスポンスが取得できませんでした")
            throw ExtractionError.externalLLMError(response: rawResponse ?? "")
        }
        
        log.debug("📝 外部LLM応答受信完了 - コンテンツ文字数: \(content.count), レスポンス全体文字数: \(rawResponse.count)")
        log.debug("📝 生レスポンス（最初の500文字）: \(String(rawResponse.prefix(500)))")
        
        // 統一されたJSON抽出処理を使用
        let (accountInfo, jsonError) = jsonExtractor.extractFromJSONText(content)
        
        if let jsonError = jsonError {
            log.error("❌ JSON抽出エラー: \(jsonError.localizedDescription)")
            throw jsonError
        }
        
        guard let accountInfo = accountInfo else {
            log.error("❌ JSON抽出結果がnilです")
            throw ExtractionError.invalidJSONFormat(aiResponse: content)
        }
        
        log.info("✅ 外部LLM JSON抽出完了")
        
        return (accountInfo, rawResponse, requestContent ?? "")
    }
}
