import Foundation

/// @ai[2025-01-17 21:00] 外部LLMクライアント
/// 目的: OpenAI互換APIを使用して外部LLMサーバーと通信
/// 背景: FoundationModelsとの性能比較のため
/// 意図: 同一プロンプトで異なるLLMの性能を客観的に比較

/// 外部LLMクライアント
/// @ai[2025-01-17 21:00] 外部LLM通信の実装
/// 目的: OpenAI互換APIを使用した外部LLM通信
/// 背景: FoundationModelsとの性能比較のため
/// 意図: 外部LLMサーバーとの通信を抽象化
@available(iOS 26.0, macOS 26.0, *)
public class ExternalLLMClient {
    private let log = LogWrapper(subsystem: "com.aitest.llm", category: "ExternalLLMClient")
    private let config: LLMConfig
    
    public init(config: LLMConfig) {
        self.config = config
        log.info("ExternalLLMClient initialized - URL: \(config.baseURL), Model: \(config.model)")
    }
    
    /// @ai[2025-01-17 21:00] JSON形式でのアカウント情報抽出
    /// 目的: FoundationModelsと同じ形式でJSON応答を取得し、性能比較を可能にする
    /// 背景: 外部LLMサーバーはOpenAI互換APIを使用
    /// 意図: 同一プロンプトで異なるLLMの性能を客観的に比較
    @MainActor
    public func extractAccountInfo(from text: String, prompt: String) async -> (String?, String?, String?, TimeInterval, Error?) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        log.info("🌐 外部LLMにプロンプト送信中...")
        log.debug("📝 プロンプト長: \(prompt.count)文字")
        log.debug("📝 入力テキスト長: \(text.count)文字")
        log.debug("🔍 DEBUG: ExternalLLMClient.extractAccountInfo呼び出し開始")
        
        // リクエストボディの構築
        let requestBody = createRequestBody(prompt: prompt)
        
        // HTTPリクエストの作成
        // baseURLに/v1が含まれている場合は除去してから/v1/chat/completionsを追加
        let cleanBaseURL = config.baseURL.hasSuffix("/v1") ? String(config.baseURL.dropLast(3)) : config.baseURL
        guard let url = URL(string: "\(cleanBaseURL)/v1/chat/completions") else {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            log.error("❌ 無効なURL: \(cleanBaseURL)")
            return (nil, nil, nil, duration, ExternalLLMError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        // リクエスト内容を文字列として保存
        let requestContent: String
        do {
            let requestData = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
            requestContent = String(data: requestData, encoding: .utf8) ?? ""
            request.httpBody = requestData
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            log.error("❌ リクエストボディの作成に失敗: \(error.localizedDescription)")
            return (nil, nil, nil, duration, ExternalLLMError.requestBodyCreationFailed)
        }
        
        log.debug("📤 HTTPリクエスト送信中...")
        log.debug("🔗 URL: \(url)")
        log.debug("📝 リクエストボディ: \(requestBody)")
        
        do {
            // HTTPリクエストの実行
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // レスポンス全体を文字列として取得（エラー時でも使用）
            let rawResponse = String(data: data, encoding: .utf8) ?? ""
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                log.error("❌ 無効なレスポンス形式")
                log.debug("📝 レスポンス全体: \(rawResponse)")
                return (nil, rawResponse, nil, duration, ExternalLLMError.invalidResponse)
            }
            
            log.debug("📥 HTTPレスポンス受信: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                log.error("❌ HTTPエラー: \(httpResponse.statusCode)")
                log.error("❌ エラーレスポンス: \(rawResponse)")
                return (nil, rawResponse, nil, duration, ExternalLLMError.httpError(httpResponse.statusCode))
            }
            
            // レスポンスの解析
            guard let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                log.error("❌ 無効なレスポンス形式")
                log.debug("📝 レスポンス全体: \(rawResponse)")
                return (nil, rawResponse, nil, duration, ExternalLLMError.invalidResponseFormat)
            }
            
            // 選択された応答を取得
            guard let choices = responseData["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                log.error("❌ レスポンスにコンテンツが見つかりません")
                log.debug("📝 レスポンス全体: \(rawResponse)")
                return (nil, rawResponse, nil, duration, ExternalLLMError.noContentInResponse)
            }
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            log.info("✅ 外部LLM応答取得成功 - 処理時間: \(String(format: "%.3f", duration))秒")
            log.debug("📝 応答内容: \(content)")
            log.debug("📝 レスポンス全体: \(rawResponse)")
                        
            return (content, rawResponse, requestContent, duration, nil)
            
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            log.error("❌ 外部LLM通信失敗: \(error.localizedDescription) - 処理時間: \(String(format: "%.3f", duration))秒")
            return (nil, nil, nil, duration, error)
        }
    }
    
    /// リクエストボディの作成
    private func createRequestBody(prompt: String) -> [String: Any] {
        return [
            "model": config.model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 1.0,
            "max_tokens": 2000,
            "top_p": 1.0
        ]
    }
}

/// @ai[2025-01-17 21:00] 外部LLM設定
/// 目的: 外部LLMサーバーの設定を管理
/// 背景: 複数の外部LLMサーバーに対応
/// 意図: 設定の一元化と型安全性の確保
@available(iOS 26.0, macOS 26.0, *)
public struct LLMConfig: Sendable {
    public let baseURL: String
    public let apiKey: String
    public let model: String
    
    public init(baseURL: String, apiKey: String, model: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
    }
}

/// @ai[2025-01-17 21:00] 外部LLMエラー
/// 目的: 外部LLM通信で発生するエラーを定義
/// 背景: エラーハンドリングの一元化
/// 意図: エラーの種類を明確に分類
@available(iOS 26.0, macOS 26.0, *)
public enum ExternalLLMError: LocalizedError {
    case invalidURL
    case requestBodyCreationFailed
    case invalidResponse
    case httpError(Int)
    case invalidResponseFormat
    case noContentInResponse
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .requestBodyCreationFailed:
            return "リクエストボディの作成に失敗しました"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .httpError(let statusCode):
            return "HTTPエラー: \(statusCode)"
        case .invalidResponseFormat:
            return "無効なレスポンス形式です"
        case .noContentInResponse:
            return "レスポンスにコンテンツが含まれていません"
        }
    }
}