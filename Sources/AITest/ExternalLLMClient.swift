import Foundation
import os

/// @ai[2025-01-17 21:00] 外部LLMサーバーとの通信クライアント
/// 目的: HTTP API経由で外部LLMサーバーと通信し、FoundationModelsとの性能比較を実現
/// 背景: ローカルLLM（gpt-oss-20b）との客観的性能比較が必要
/// 意図: OpenAI互換APIを使用して外部LLMの応答を取得し、同じテストケースで比較評価

@available(iOS 26.0, macOS 26.0, *)
public final class ExternalLLMClient: ObservableObject {
    private let logger = Logger(subsystem: "com.aitest.external", category: "ExternalLLMClient")
    
    /// 外部LLMサーバーの設定
    public struct LLMConfig: Sendable {
        public let baseURL: String
        public let apiKey: String
        public let model: String
        public let maxTokens: Int
        public let temperature: Double
        
        public init(baseURL: String, apiKey: String = "EMPTY", model: String, maxTokens: Int = 500, temperature: Double = 0.3) {
            self.baseURL = baseURL
            self.apiKey = apiKey
            self.model = model
            self.maxTokens = maxTokens
            self.temperature = temperature
        }
    }
    
    private let config: LLMConfig
    
    /// イニシャライザ
    public init(config: LLMConfig) {
        self.config = config
        logger.info("ExternalLLMClient initialized with baseURL: \(config.baseURL)")
    }
    
    /// 外部LLMにプロンプトを送信してJSON応答を取得
    /// @ai[2025-01-17 21:00] JSON形式でのアカウント情報抽出
    /// 目的: FoundationModelsと同じ形式でJSON応答を取得し、性能比較を可能にする
    /// 背景: 外部LLMサーバーはOpenAI互換APIを使用
    /// 意図: 同一プロンプトで異なるLLMの性能を客観的に比較
    @MainActor
    public func extractAccountInfo(from text: String, prompt: String) async throws -> (String, TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        logger.info("🌐 外部LLMにプロンプト送信中...")
        logger.debug("📝 プロンプト長: \(prompt.count)文字")
        logger.debug("📝 入力テキスト長: \(text.count)文字")
        
        do {
            // リクエストボディの構築
            let requestBody = createRequestBody(prompt: prompt)
            
            // HTTPリクエストの作成
            guard let url = URL(string: "\(config.baseURL)/v1/chat/completions") else {
                throw ExternalLLMError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            logger.debug("🌐 リクエスト送信: \(url)")
            
            // ネットワークリクエストの実行
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // レスポンスの検証
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ExternalLLMError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                logger.error("❌ HTTPエラー: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    logger.error("❌ エラーレスポンス: \(errorData)")
                }
                throw ExternalLLMError.httpError(httpResponse.statusCode)
            }
            
            // レスポンスの解析
            let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let responseData = responseData else {
                throw ExternalLLMError.invalidResponseFormat
            }
            
            // 選択された応答を取得
            guard let choices = responseData["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw ExternalLLMError.noContentInResponse
            }
            
            // エスケープされたJSON文字列をデコード
            let decodedContent = content
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\t", with: "\t")
                .replacingOccurrences(of: "\\r", with: "\r")
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("✅ 外部LLM応答取得成功 - 処理時間: \(String(format: "%.3f", duration))秒")
            logger.debug("📝 応答内容: \(decodedContent)")
            
            // デバッグ用: 応答内容をファイルに保存
            let debugDir = FileManager.default.temporaryDirectory.appendingPathComponent("external_llm_debug")
            try? FileManager.default.createDirectory(at: debugDir, withIntermediateDirectories: true)
            let debugFile = debugDir.appendingPathComponent("response_\(Date().timeIntervalSince1970).txt")
            try? decodedContent.write(to: debugFile, atomically: true, encoding: .utf8)
            logger.debug("📁 デバッグファイル保存: \(debugFile.path)")
            
            return (decodedContent, duration)
            
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.error("❌ 外部LLM通信失敗: \(error.localizedDescription) - 処理時間: \(String(format: "%.3f", duration))秒")
            throw error
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
            "max_tokens": 4096,
            "temperature": 1.0,
            "top_p": 1.0
        ]
    }
}

/// @ai[2025-01-17 21:00] 外部LLM関連のエラー定義
/// 目的: 外部LLM通信で発生する可能性のあるエラーを型安全に処理
/// 背景: ネットワーク通信、JSON解析、API応答の検証でエラーが発生する可能性
/// 意図: 適切なエラーハンドリングとデバッグ情報の提供
@available(iOS 26.0, macOS 26.0, *)
public enum ExternalLLMError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case invalidResponseFormat
    case noContentInResponse
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なHTTPレスポンスです"
        case .httpError(let code):
            return "HTTPエラー: \(code)"
        case .invalidResponseFormat:
            return "無効なレスポンス形式です"
        case .noContentInResponse:
            return "レスポンスにコンテンツが含まれていません"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}
