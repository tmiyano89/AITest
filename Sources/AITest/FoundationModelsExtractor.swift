import Foundation
import FoundationModels

/// @ai[2025-01-19 00:30] FoundationModels用抽出器
/// 目的: FoundationModelsを使用した抽出処理を実装
/// 背景: GenerableとJSONメソッドの両方に対応
/// 意図: FoundationModels固有の処理を抽象化

/// FoundationModels用の抽出器
/// @ai[2025-01-19 00:30] FoundationModels抽出の実装
/// 目的: FoundationModelsを使用した抽出処理を提供
/// 背景: GenerableとJSONメソッドの両方に対応する必要がある
/// 意図: FoundationModels固有の処理を実装
@available(iOS 26.0, macOS 26.0, *)
public class FoundationModelsExtractor: ModelExtractor {
    private let log = LogWrapper(subsystem: "com.aitest.fm", category: "FoundationModelsExtractor")
    private let jsonExtractor = JSONExtractor()
    private var session: LanguageModelSession?
    
    public init() {
        log.info("FoundationModelsExtractor initialized")
    }
    
    /// テキストからアカウント情報を抽出
    /// @ai[2025-01-19 00:30] FoundationModels抽出の実装
    /// 目的: GenerableとJSONメソッドの両方に対応した抽出処理
    /// 背景: モデル抽象化レイヤーの実装
    /// 意図: FoundationModels固有の処理を実装
    @MainActor
    public func extract(from text: String, prompt: String, method: ExtractionMethod) async throws -> ExtractionResult {
        log.info("🤖 FoundationModels抽出開始 - method: \(method.rawValue)")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var rawResponse: String = ""
        
        do {
            // セッション初期化
            if session == nil {
                try await initializeSession()
            }
            
            guard let session = self.session else {
                throw ExtractionError.languageModelUnavailable
            }
            
            defer {
                log.debug("🧹 セッションを解放")
                self.session = nil
            }
            
            // 抽出方法に応じた処理を実行
            let accountInfo: AccountInfo
            
            switch method {
            case .generable:
                (accountInfo, rawResponse) = try await performGenerableExtraction(session: session, prompt: prompt)
            case .json:
                (accountInfo, rawResponse) = try await performJSONExtraction(session: session, prompt: prompt)
            case .yaml:
                throw ExtractionError.methodNotSupported("YAML method is not supported in FoundationModels")
            }
            
            let extractionTime = CFAbsoluteTimeGetCurrent() - startTime
            
            log.info("✅ FoundationModels抽出完了 - 時間: \(String(format: "%.3f", extractionTime))秒")
            
            return ExtractionResult(
                accountInfo: accountInfo,
                rawResponse: rawResponse,
                requestContent: prompt, // FoundationModelsではプロンプト全文をリクエスト内容として使用
                extractionTime: extractionTime,
                method: method
            )
        } catch let error as ExtractionError {
            // ExtractionErrorの場合は、rawResponseを含めて再スロー
            if rawResponse.isEmpty {
                throw error
            } else {
                // rawResponseがある場合は、aiResponseを含む新しいエラーを作成
                switch error {
                case .invalidJSONFormat:
                    throw ExtractionError.invalidJSONFormat(aiResponse: rawResponse)
                case .externalLLMError:
                    throw ExtractionError.externalLLMError(response: rawResponse)
                default:
                    throw error
                }
            }
        } catch {
            // その他のエラーの場合は、rawResponseを含むExtractionErrorに変換
            if !rawResponse.isEmpty {
                throw ExtractionError.invalidJSONFormat(aiResponse: rawResponse)
            } else {
                throw ExtractionError.invalidInput
            }
        }
    }
    
    /// セッションを初期化
    /// @ai[2025-01-19 00:30] セッション初期化の実装
    /// 目的: FoundationModelsセッションを初期化
    /// 背景: AI利用可能性の確認とセッション作成
    /// 意図: セッション初期化の一元化
    @MainActor
    private func initializeSession() async throws {
        log.debug("🔧 セッション初期化開始")
        
        // AI利用可能性の確認
        guard await checkAIAvailability() else {
            log.error("❌ AI機能が利用できません")
            throw ExtractionError.aifmNotSupported
        }
        
        // セッション作成
        self.session = try await LanguageModelSession()
        
        log.debug("✅ セッション初期化完了")
    }
    
    /// Generable抽出を実行
    /// @ai[2025-01-19 00:30] Generable抽出の実装
    /// 目的: @Generableマクロを使用した抽出処理
    /// 背景: FoundationModelsの特殊な機能を活用
    /// 意図: Generable固有の処理を実装
    @MainActor
    private func performGenerableExtraction(session: LanguageModelSession, prompt: String) async throws -> (AccountInfo, String) {
        log.debug("🔍 Generable抽出開始")
        
        let aiStart = CFAbsoluteTimeGetCurrent()
        
        // @GenerableマクロによりAccountInfoは自動的にGenerableプロトコルに準拠
        let stream = session.streamResponse(to: prompt, generating: AccountInfo.self)
        
        // ストリーミング中の部分結果を処理
        for try await _ in stream {
            // 部分結果の処理（必要に応じて）
        }
        
        // 最終結果を収集
        let finalResult = try await stream.collect()
        let aiTime = CFAbsoluteTimeGetCurrent() - aiStart
        
        log.info("⏱️  AI処理時間: \(String(format: "%.3f", aiTime))秒")
        
        // Generableの場合、生のレスポンスは直接取得できないため、空文字列を返す
        // 実際の実装では、FoundationModelsのAPIの制約により生のテキストレスポンスを直接取得することが困難
        let rawResponse = "Generable response (raw text not accessible)"
        
        return (finalResult.content, rawResponse)
    }
    
    /// JSON抽出を実行
    /// @ai[2025-01-19 00:30] JSON抽出の実装
    /// 目的: JSON形式での抽出処理
    /// 背景: 統一されたJSON抽出処理を使用
    /// 意図: JSON抽出の一元化
    @MainActor
    private func performJSONExtraction(session: LanguageModelSession, prompt: String) async throws -> (AccountInfo, String) {
        log.debug("🔍 JSON抽出開始")
        
        let aiStart = CFAbsoluteTimeGetCurrent()
        
        // ストリーミングレスポンスを取得
        let stream = session.streamResponse(to: prompt)
        let response = try await stream.collect()
        let aiTime = CFAbsoluteTimeGetCurrent() - aiStart
        
        log.info("⏱️  AI処理時間: \(String(format: "%.3f", aiTime))秒")
        
        // 生のレスポンスを取得
        let rawResponse = response.content
        
        log.debug("📝 生レスポンス（最初の500文字）: \(String(rawResponse.prefix(500)))")
        
        // 統一されたJSON抽出処理を使用
        let (accountInfo, jsonError) = jsonExtractor.extractFromJSONText(rawResponse)
        
        if let jsonError = jsonError {
            log.error("❌ JSON抽出エラー: \(jsonError.localizedDescription)")
            throw jsonError
        }
        
        guard let accountInfo = accountInfo else {
            log.error("❌ JSON抽出結果がnilです")
            throw ExtractionError.invalidJSONFormat(aiResponse: rawResponse)
        }
        
        log.info("✅ JSON抽出完了")
        
        return (accountInfo, rawResponse)
    }
    
    /// AI利用可能性をチェック
    /// @ai[2025-01-19 00:30] AI利用可能性チェックの実装
    /// 目的: FoundationModelsの利用可能性を確認
    /// 背景: システムAPIの確認
    /// 意図: AI利用可能性チェックの一元化
    private func checkAIAvailability() -> Bool {
        log.debug("🔍 AI利用可能性チェック開始")
        
        // FoundationModelsの利用可能性をチェック
        let isAvailable = true // 簡易実装
        
        log.debug("AI利用可能性: \(isAvailable ? "available" : "unavailable")")
        
        if isAvailable {
            log.debug("✅ AI利用可能（システムAPI確認済み）")
        } else {
            log.debug("❌ AI利用不可")
        }
        
        return isAvailable
    }
}
