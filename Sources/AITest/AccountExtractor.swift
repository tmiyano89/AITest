import Foundation
import FoundationModels
import Vision
import os.log

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif


/// @ai[2024-12-19 17:00] 言語選択の列挙型
/// 目的: 日本語と英語での抽出精度比較を可能にする
/// 背景: プロンプト言語が抽出精度に与える影響を評価
/// 意図: 多言語対応による抽出性能の最適化
@available(iOS 26.0, macOS 26.0, *)
public enum PromptLanguage: String, CaseIterable, Codable, Sendable {
    case japanese = "ja"
    case english = "en"
    
    public var displayName: String {
        switch self {
        case .japanese:
            return "日本語"
        case .english:
            return "English"
        }
    }
    
    public var description: String {
        switch self {
        case .japanese:
            return "日本語プロンプトを使用した抽出"
        case .english:
            return "English prompt for extraction"
        }
    }
}

/// @ai[2024-12-19 16:00] Account情報抽出サービス
/// FoundationModelsのLanguageSessionModelを使用して画像やテキストからAccount情報を抽出
@available(iOS 26.0, macOS 26.0, *)
public final class AccountExtractor: ObservableObject {
    private let log = LogWrapper(subsystem: "com.aitest.extractor", category: "AccountExtractor")
    
    /// LanguageModelSession
    private var session: LanguageModelSession?
    
    /// 処理中のタスク
    private var currentTask: Task<Void, Never>?
    
    /// 設定
    private var temperature: Double = 0.1
    private var maxTokens: Int = 500
    private var language: String = "ja"
    
    /// イニシャライザ
    public init() {
        log.info("AccountExtractor initialized")
    }
    
    /// デイニシャライザ
    deinit {
        log.info("AccountExtractor deinitialized")
        cancel()
    }
    
    /// テキストからアカウント情報を抽出（@Generableマクロ使用）
    /// @ai[2024-12-19 16:00] 性能測定用の抽出処理
    /// 目的: FoundationModelsを使用したAccount情報抽出の性能を測定
    /// 背景: LanguageSessionModelの推論時間、メモリ使用量、精度を評価
    /// 意図: 数値的な性能データを収集し、最適化の指針を提供
    @MainActor
    public func extractFromText(_ text: String, method: ExtractionMethod = .generable, language: PromptLanguage = .japanese, pattern: ExperimentPattern = .defaultPattern, externalLLMConfig: ExternalLLMClient.LLMConfig? = nil) async throws -> (AccountInfo, ExtractionMetrics) {
        log.success("AccountExtractor.extractFromText開始 - 外部LLM: \(externalLLMConfig != nil ? "あり" : "なし")")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let memoryBefore = getMemoryUsage()
        
        defer { 
            log.success("AccountExtractor.extractFromText完了") 
        }
        
        do {
            log.success("AccountExtractor doブロック開始")
            // AI利用可能性の事前チェック
            guard await checkAIAvailability() else {
                log.error("❌ AI機能が利用できません")
                throw ExtractionError.aifmNotSupported
            }
            log.success("AI利用可能性チェック完了")
            
            // 入力検証
            log.success("入力検証開始")
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                log.error("❌ 入力検証失敗: 空のテキスト")
                throw ExtractionError.invalidInput
            }
            log.success("入力検証完了 - 文字数: \(text.count)")
            
            // セッション初期化（外部LLMが設定されていない場合のみ）
            print("✅ セッション初期化開始")
            if externalLLMConfig == nil && session == nil {
                try await initializeSession(pattern: pattern, language: language)
                print("✅ FoundationModelsセッション初期化完了")
                log.info("✅ FoundationModelsセッション初期化完了")
            } else if externalLLMConfig != nil {
                print("✅ 外部LLM使用のためセッション初期化スキップ")
                log.info("✅ 外部LLM使用のためセッション初期化スキップ")
            }
            
            // 抽出処理実行
            print("✅ 抽出処理開始 - 方法: \(method.rawValue)")
            log.info("✅ 抽出処理開始 - 方法: \(method.rawValue)")
            let (accountInfo, extractionTime) = try await performExtraction(from: text, method: method, language: language, pattern: pattern, externalLLMConfig: externalLLMConfig)
            print("✅ 抽出処理完了 - 時間: \(String(format: "%.3f", extractionTime))秒")
            log.info("✅ 抽出処理完了 - 時間: \(String(format: "%.3f", extractionTime))秒")
            
            // バリデーション（警告のみ、処理は中断しない）
            let validationResult = accountInfo.validate()
            if !validationResult.isValid {
                log.warning("⚠️ バリデーション警告: \(validationResult.warnings.count)個の警告")
                for warning in validationResult.warnings {
                    log.warning("  - \(warning.errorDescription ?? "不明な警告")")
                }
            } else {
                log.info("✅ 抽出結果バリデーション完了（警告なし）")
            }
            
            // メトリクス計算
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            let memoryAfter = getMemoryUsage()
            let memoryUsed = memoryAfter - memoryBefore
            
            let metrics = ExtractionMetrics(
                extractionTime: extractionTime,
                totalTime: totalTime,
                memoryUsed: memoryUsed,
                textLength: text.count,
                extractedFieldsCount: accountInfo.extractedFieldsCount,
                confidence: accountInfo.confidence ?? 0.0,
                isValid: validationResult.isValid,
                validationResult: validationResult
            )
            
            log.info("📊 抽出結果統計 - フィールド数: \(accountInfo.extractedFieldsCount), 信頼度: \(String(format: "%.2f", accountInfo.confidence ?? 0))")
            
            return (accountInfo, metrics)
            
        } catch {
            log.error("❌ テキスト抽出処理でエラー: \(error.localizedDescription)")
            log.debug("🔍 DEBUG: エラーの詳細: \(error)")
            throw error
        }
    }
    
    
    /// 処理をキャンセル
    public func cancel() {
        log.info("🛑 抽出処理をキャンセル")
        currentTask?.cancel()
        currentTask = nil
        session = nil
    }
    
    // MARK: - Private Methods
    
    /// AI利用可能性をチェック（システムAPI使用）
    /// @ai[2024-12-19 16:30] Apple公式APIを使用したAI利用可能性チェック
    /// 目的: システムAPIの結果のみに依存してAI利用可能性を判定
    /// 背景: iOS 18.2+を最小ターゲットとし、FoundationModelsはiOS 26+で利用可能
    /// 意図: 自己判断を避け、システムが提供する正確な情報を使用
    @MainActor
    private func checkAIAvailability() async -> Bool {
        log.info("✅ AI利用可能性チェック開始")
        
        // システムAPIを使用してAI利用可能性をチェック
        let systemModel = SystemLanguageModel.default
        let availability = systemModel.availability
        log.info("✅ AI利用可能性: \(String(describing: availability))")
        
        switch availability {
        case .available:
            log.info("✅ AI利用可能（システムAPI確認済み）")
            return true
            
        case .unavailable(.appleIntelligenceNotEnabled):
            log.error("❌ Apple Intelligenceが無効です（システムAPI確認済み）")
            log.error("設定 > Apple Intelligence でApple Intelligenceを有効にしてください")
            return false
            
        case .unavailable(.deviceNotEligible):
            log.error("❌ このデバイスではAIモデルを利用できません（システムAPI確認済み）")
            log.error("iPhone 15 Pro以降、またはM1以降のMacが必要です")
            return false
            
        case .unavailable(.modelNotReady):
            log.error("❌ AIモデルをダウンロード中です（システムAPI確認済み）")
            log.error("モデルのダウンロードが完了するまでお待ちください")
            return false
            
        case .unavailable(let reason):
            log.error("❌ Apple Intelligence利用不可（システムAPI確認済み）: \(String(describing: reason))")
            return false
        }
    }
    
    
    /// セッションを初期化
    @MainActor
    private func initializeSession(pattern: ExperimentPattern = .defaultPattern, language: PromptLanguage = .japanese) async throws {
        log.debug("🔧 セッション初期化開始")
        
        // AI利用可能性をチェック
        guard await checkAIAvailability() else {
            log.error("❌ AI機能が利用できません")
            throw ExtractionError.aifmNotSupported
        }
        
        log.info("✅ AI利用可能性チェック完了")
        
        // FoundationModelsを使用してセッションを初期化
        let sessionInstructions = PromptTemplateGenerator.generateSessionInstructions(for: pattern, language: language)
        session = LanguageModelSession(
            instructions: Instructions {
                sessionInstructions
            }
        )
        log.info("✅ セッション初期化完了")
    }
    
    
    
    /// 抽出処理を実行
    @MainActor
    private func performExtraction(from text: String, method: ExtractionMethod, language: PromptLanguage, pattern: ExperimentPattern, externalLLMConfig: ExternalLLMClient.LLMConfig? = nil) async throws -> (AccountInfo, TimeInterval) {
        print("✅ performExtraction開始")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 外部LLMが指定されている場合は外部LLMを使用
        if let externalConfig = externalLLMConfig {
            print("✅ 外部LLM使用 - URL: \(externalConfig.baseURL)")
            log.info("✅ 外部LLM使用 - URL: \(externalConfig.baseURL)")
            
            // @ai[2025-01-18 07:00] 外部LLM設定のassertion
            assert(!externalConfig.baseURL.isEmpty, "外部LLMのbaseURLが空です")
            assert(!externalConfig.model.isEmpty, "外部LLMのmodelが空です")
            assert(externalConfig.maxTokens > 0, "外部LLMのmaxTokensが0以下です: \(externalConfig.maxTokens)")
            assert(externalConfig.temperature >= 0.0 && externalConfig.temperature <= 2.0, "外部LLMのtemperatureが範囲外です: \(externalConfig.temperature)")
            
            print("✅ performExternalLLMExtraction呼び出し開始")
            return try await performExternalLLMExtraction(text: text, startTime: startTime, language: language, pattern: pattern, config: externalConfig)
        } else {
            print("✅ FoundationModels使用")
            log.info("✅ FoundationModels使用")
        }
        
        guard let session = self.session else {
            log.error("❌ セッションが初期化されていません")
            throw ExtractionError.languageModelUnavailable
        }
        
        // セッションは既にLanguageModelSessionとして初期化済み
        
        defer {
            log.debug("🧹 セッションを解放")
            self.session = nil
        }
        
        // 抽出方法に応じた処理を実行
        let accountInfo: AccountInfo
        let duration: TimeInterval
        
        switch method {
        case .generable:
            (accountInfo, duration) = try await performGenerableExtraction(session: session, text: text, startTime: startTime, language: language, pattern: pattern)
        case .json:
            (accountInfo, duration) = try await performJSONExtraction(session: session, text: text, startTime: startTime, language: language, pattern: pattern)
        case .yaml:
            (accountInfo, duration) = try await performYAMLExtraction(session: session, text: text, startTime: startTime, language: language, pattern: pattern)
        }
        
        return (accountInfo, duration)
    }
    
    /// @ai[2025-01-17 21:00] 外部LLMを使用した抽出処理
    /// 目的: 外部LLMサーバーを使用してJSON形式でアカウント情報を抽出
    /// 背景: FoundationModelsとの性能比較のため、同一プロンプトで外部LLMを実行
    /// 意図: 客観的な性能比較データを収集し、最適なLLM選択の指針を提供
    @MainActor
    private func performExternalLLMExtraction(text: String, startTime: CFAbsoluteTime, language: PromptLanguage, pattern: ExperimentPattern, config: ExternalLLMClient.LLMConfig) async throws -> (AccountInfo, TimeInterval) {
        print("✅ performExternalLLMExtraction開始")
        log.info("🌐 外部LLM抽出処理開始")
        log.info("🔍 外部LLM設定: \(config.baseURL), モデル: \(config.model)")
        
        // @ai[2025-01-18 07:00] 外部LLM抽出処理のassertion
        assert(!text.isEmpty, "抽出対象テキストが空です")
        assert(!config.baseURL.isEmpty, "外部LLMのbaseURLが空です")
        assert(!config.model.isEmpty, "外部LLMのmodelが空です")
        print("✅ 外部LLM抽出処理の入力assertion通過")
        log.debug("✅ 外部LLM抽出処理の入力assertion通過")
        
        // 外部LLMクライアントの初期化
        print("✅ ExternalLLMClient初期化")
        let externalClient = ExternalLLMClient(config: config)
        
        // プロンプト生成（JSON形式）
        print("✅ プロンプト生成開始")
        let promptStart = CFAbsoluteTimeGetCurrent()
        let prompt = PromptTemplateGenerator.generatePrompt(for: pattern, language: language, inputData: text)
        let promptTime = CFAbsoluteTimeGetCurrent() - promptStart
        print("✅ プロンプト生成完了 - 文字数: \(prompt.count)")
        log.debug("📝 プロンプト生成完了 - プロンプト文字数: \(prompt.count), 処理時間: \(String(format: "%.3f", promptTime))秒")
        
        // 外部LLMにプロンプトを送信
        print("✅ 外部LLM抽出処理実行開始")
        log.info("🤖 外部LLM抽出処理を実行")
        
        let (response, aiDuration) = try await externalClient.extractAccountInfo(from: text, prompt: prompt)
        print("✅ 外部LLM応答受信完了 - 応答文字数: \(response.count)")
        
        // @ai[2025-01-18 07:00] 外部LLM応答のassertion
        assert(!response.isEmpty, "外部LLMからの応答が空です")
        assert(aiDuration > 0, "外部LLM処理時間が0以下です: \(aiDuration)")
        print("✅ 外部LLM応答のassertion通過")
        log.debug("✅ 外部LLM応答のassertion通過")
        
        print("✅ 外部LLM応答取得成功 - AI処理時間: \(String(format: "%.3f", aiDuration))秒")
        log.info("✅ 外部LLM応答取得成功 - AI処理時間: \(String(format: "%.3f", aiDuration))秒")
        log.debug("📝 外部LLM応答: \(response)")
        
        // デバッグ用: 応答内容をファイルに保存
        print("✅ デバッグファイル保存開始")
        let debugDir = FileManager.default.temporaryDirectory.appendingPathComponent("external_llm_debug")
        try? FileManager.default.createDirectory(at: debugDir, withIntermediateDirectories: true)
        let debugFile = debugDir.appendingPathComponent("response_\(Date().timeIntervalSince1970).txt")
        try? response.write(to: debugFile, atomically: true, encoding: String.Encoding.utf8)
        print("✅ デバッグファイル保存完了: \(debugFile.path)")
        log.debug("📁 デバッグファイル保存: \(debugFile.path)")
        
        // @ai[2025-01-18 07:00] デバッグ情報のassertion
        assert(FileManager.default.fileExists(atPath: debugFile.path), "デバッグファイルが保存されていません: \(debugFile.path)")
        print("✅ デバッグファイル保存のassertion通過")
        log.debug("✅ デバッグファイル保存のassertion通過")
        
        // JSON応答をAccountInfoに変換（真のリトライ機能付き）
        print("✅ JSON解析開始")
        let parseStart = CFAbsoluteTimeGetCurrent()
        let accountInfo = try await performExternalLLMExtractionWithRetry(
            externalClient: externalClient,
            text: text,
            prompt: prompt,
            maxRetries: 3
        )
        let parseTime = CFAbsoluteTimeGetCurrent() - parseStart
        
        // @ai[2025-01-18 07:00] JSON解析結果のassertion
        assert(parseTime > 0, "JSON解析時間が0以下です: \(parseTime)")
        assert(accountInfo.extractedFieldsCount >= 0, "抽出フィールド数が負の値です: \(accountInfo.extractedFieldsCount)")
        log.debug("✅ JSON解析結果のassertion通過")
        
        log.info("✅ JSON解析完了 - 解析時間: \(String(format: "%.3f", parseTime))秒")
        
        let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
        log.info("✅ 外部LLM抽出処理成功 - 総処理時間: \(String(format: "%.3f", totalDuration))秒")
        
        return (accountInfo, totalDuration)
    }
    
    /// @ai[2025-01-18 08:10] 真のリトライ機能付き外部LLM抽出処理
    /// 目的: パースエラーが発生した場合に新しいリクエストを送信してリトライ
    /// 背景: temperature=1.0の設定で異なるレスポンスを取得し、パースエラーを回避
    /// 意図: 偶発的なパースエラーを真のリトライで解決
    @MainActor
    private func performExternalLLMExtractionWithRetry(
        externalClient: ExternalLLMClient,
        text: String,
        prompt: String,
        maxRetries: Int
    ) async throws -> AccountInfo {
        log.info("✅ 真のリトライ機能付き外部LLM抽出処理開始 - 最大リトライ: \(maxRetries)")
        
        var lastError: Error?
        var previousResponses: [String] = []
        
        for attempt in 1...maxRetries {
            log.info("🔄 外部LLM抽出試行 \(attempt)/\(maxRetries)")
            
            do {
                // 新しいリクエストを送信
                let (response, _) = try await externalClient.extractAccountInfo(from: text, prompt: prompt)
                log.info("✅ 外部LLM応答受信完了 - 応答文字数: \(response.count)")
                
                
                // レスポンス変化チェック（2回目以降）
                if attempt > 1 {
                    let responseHash = String(response.hashValue)
                    if previousResponses.contains(responseHash) {
                        log.warning("⚠️ レスポンス変化なし（試行\(attempt)回目）: 同じレスポンスが繰り返されています")
                    } else {
                        log.info("✅ レスポンス変化あり（試行\(attempt)回目）: 新しいレスポンスを受信")
                    }
                    previousResponses.append(responseHash)
                }
                
                // JSON解析を試行
                let accountInfo = try parseJSONToAccountInfo(response)
                log.info("✅ JSON解析成功（試行\(attempt)回目）")
                
                return accountInfo
            } catch {
                lastError = error
                log.warning("❌ 外部LLM抽出失敗（試行\(attempt)回目）: \(error.localizedDescription)")
                
                // リトライ機能: 次の試行まで少し待機
                if attempt < maxRetries {
                    log.info("🔄 リトライ準備中... (試行\(attempt + 1)/\(maxRetries))")
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
                }
            }
        }
        
        log.error("❌ 全\(maxRetries)回の外部LLM抽出試行が失敗")
        throw lastError ?? ExtractionError.invalidJSONFormat(aiResponse: nil)
    }
    
    /// @ai[2025-01-18 07:00] デバッグ用ユーティリティ
    /// 目的: デグレーションを即座に検出するためのデバッグ情報を出力
    /// 背景: 同じ問題で何度もデグレが発生するため、詳細なログとassertionが必要
    /// 意図: 問題の早期発見と迅速な修正を可能にする
    private func logDebugInfo(_ message: String, context: [String: Any] = [:]) {
        log.debug("🔍 DEBUG: \(message)")
        for (key, value) in context {
            log.debug("  \(key): \(String(describing: value))")
        }
    }
    
    /// @ai[2025-01-18 07:00] 外部LLM設定検証
    /// 目的: 外部LLM設定の妥当性を検証し、デグレを防止する
    /// 背景: 設定が不正な場合に処理が失敗するため、事前検証が必要
    /// 意図: 設定ミスによる実行時エラーを事前に防ぐ
    private func validateExternalLLMConfig(_ config: ExternalLLMClient.LLMConfig) -> Bool {
        guard !config.baseURL.isEmpty else {
            log.error("❌ 外部LLM設定エラー: baseURLが空です")
            return false
        }
        guard !config.model.isEmpty else {
            log.error("❌ 外部LLM設定エラー: modelが空です")
            return false
        }
        guard config.maxTokens > 0 else {
            log.error("❌ 外部LLM設定エラー: maxTokensが0以下です: \(config.maxTokens)")
            return false
        }
        guard config.temperature >= 0.0 && config.temperature <= 2.0 else {
            log.error("❌ 外部LLM設定エラー: temperatureが範囲外です: \(config.temperature)")
            return false
        }
        log.debug("✅ 外部LLM設定検証通過")
        return true
    }
    
    /// @ai[2025-01-17 21:00] 外部LLM用JSON解析メソッド
    /// 目的: 外部LLMからのJSON応答をAccountInfoに変換
    /// 背景: 外部LLMは異なる形式でJSONを返す可能性があるため、専用の解析が必要
    /// 意図: 外部LLMの応答形式に柔軟に対応し、正確なデータ抽出を実現
    private func parseJSONToAccountInfo(_ jsonString: String) throws -> AccountInfo {
        log.debug("🔍 外部LLM JSON文字列解析開始")
        log.debug("📝 JSON文字列: \(jsonString)")
        
        // 最初にJSON文字列をサニタイズ
        let sanitizedJSON = sanitizeJSONString(jsonString)
        
        // 複数のJSON抽出パターンを試行
        let jsonPatterns = [
            // パターン1: ```json ... ``` で囲まれたJSON
            extractJSONFromCodeBlock(sanitizedJSON),
            // パターン2: assistantfinal の後のJSON
            extractJSONAfterAssistantFinal(sanitizedJSON),
            // パターン3: 最初の{から最後の}まで
            extractJSONFromBraces(sanitizedJSON),
            // パターン4: 全体がJSON
            sanitizedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        
        for (index, jsonCandidate) in jsonPatterns.enumerated() {
            guard !jsonCandidate.isEmpty else { continue }
            
            log.debug("📝 パターン\(index + 1) JSON候補: \(jsonCandidate)")
            
            // ポート番号の文字列を数値に変換してからパース
            let normalizedJSON = normalizePortField(jsonCandidate)
            
            if let accountInfo = tryParseJSON(normalizedJSON) {
                log.debug("✅ 外部LLM JSON解析完了（パターン\(index + 1)）")
                return accountInfo
            }
        }
        
        log.error("❌ すべてのJSON抽出パターンが失敗")
        log.error("📝 レスポンス全体: \(jsonString)")
        throw ExtractionError.invalidJSONFormat(aiResponse: jsonString)
    }
    
    /// ```json ... ``` で囲まれたJSONを抽出
    private func extractJSONFromCodeBlock(_ text: String) -> String {
        let codeBlockPattern = #"```json\s*([\s\S]*?)\s*```"#
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let jsonRange = Range(match.range(at: 1), in: text) {
                    let extractedJSON = String(text[jsonRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "\\n", with: "\n")
                        .replacingOccurrences(of: "\\t", with: "\t")
                        .replacingOccurrences(of: "\\r", with: "\r")
                    return extractedJSON
                }
            }
        }
        return ""
    }
    
    /// assistantfinal の後のJSONを抽出
    private func extractJSONAfterAssistantFinal(_ text: String) -> String {
        let assistantFinalPattern = #"assistantfinal\s*(\{[\s\S]*\})"#
        if let regex = try? NSRegularExpression(pattern: assistantFinalPattern, options: []) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let jsonRange = Range(match.range(at: 1), in: text) {
                    return String(text[jsonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return ""
    }
    
    /// 最初の{から最後の}までのJSONを抽出
    private func extractJSONFromBraces(_ text: String) -> String {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else {
            return ""
        }
        let extractedJSON = String(text[start...end])
        return extractedJSON
    }
    
    /// @ai[2025-01-18 06:45] JSON文字列のサニタイズ
    /// 目的: 制御文字や改行文字をエスケープしてJSON解析を可能にする
    /// 背景: 外部LLMが複数行の文字列を含むJSONを返す場合、制御文字で解析エラーが発生
    /// 意図: 改行文字を\\nにエスケープし、JSONの有効性を確保する
    private func sanitizeJSONString(_ jsonString: String) -> String {
        log.debug("🔧 JSON文字列サニタイズ開始")
        log.debug("📝 元のJSON: \(jsonString)")
        
        var sanitized = jsonString
        
        // バックスラッシュを最初にエスケープ（他のエスケープ処理の前に実行）
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "\\\\")
        
        // 改行文字をエスケープ
        sanitized = sanitized.replacingOccurrences(of: "\n", with: "\\n")
        sanitized = sanitized.replacingOccurrences(of: "\r", with: "\\r")
        sanitized = sanitized.replacingOccurrences(of: "\t", with: "\\t")
        
        log.debug("📝 サニタイズ後JSON: \(sanitized)")
        
        return sanitized
    }
    
    /// ポート番号の文字列を数値に変換
    /// @ai[2025-01-18 09:00] 外部LLMが文字列でポート番号を返す問題を解決
    /// 目的: "port": "22" を "port": 22 に変換してJSONデコードエラーを回避
    /// 背景: AccountInfo.portはInt型だが、外部LLMが文字列で返すことがある
    /// 意図: 型の不一致によるデコードエラーを防ぎ、抽出成功率を向上
    private func normalizePortField(_ jsonString: String) -> String {
        // "port": "22" のパターンを "port": 22 に変換
        let portPattern = #""port"\s*:\s*"(\d+)""#
        if let regex = try? NSRegularExpression(pattern: portPattern, options: []) {
            let range = NSRange(jsonString.startIndex..<jsonString.endIndex, in: jsonString)
            var normalizedJSON = jsonString
            var offset = 0
            
            regex.enumerateMatches(in: jsonString, options: [], range: range) { match, _, _ in
                guard let match = match,
                      let portRange = Range(match.range(at: 1), in: jsonString) else { return }
                
                let portString = String(jsonString[portRange])
                let replacement = "\"port\": \(portString)"
                
                // 範囲を調整（前の置換によるオフセットを考慮）
                let adjustedRange = NSRange(
                    location: match.range.location - offset,
                    length: match.range.length
                )
                
                normalizedJSON = (normalizedJSON as NSString).replacingCharacters(
                    in: adjustedRange,
                    with: replacement
                )
                
                offset += match.range.length - replacement.count
            }
            
            return normalizedJSON
        }
        return jsonString
    }
    
    /// JSON文字列をAccountInfoに変換（エラーハンドリング付き）
    private func tryParseJSON(_ jsonString: String) -> AccountInfo? {
        guard let data = jsonString.data(using: .utf8) else {
            log.debug("❌ UTF-8変換失敗: \(jsonString)")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let accountInfo = try decoder.decode(AccountInfo.self, from: data)
            log.debug("✅ AccountInfoデコード成功")
            return accountInfo
        } catch let decodingError as DecodingError {
            log.debug("❌ JSONデコードエラー: \(decodingError)")
            log.debug("📝 デコード対象: \(String(data: data, encoding: .utf8) ?? "変換失敗")")
            return nil
        } catch {
            log.debug("❌ 予期しないエラー: \(error)")
            return nil
        }
    }
    
    /// @Generableマクロを使用した抽出処理
    @MainActor
    private func performGenerableExtraction(session: LanguageModelSession, text: String, startTime: CFAbsoluteTime, language: PromptLanguage, pattern: ExperimentPattern) async throws -> (AccountInfo, TimeInterval) {
        log.debug("🔍 @Generableマクロ抽出処理開始")
        
        // プロンプトを生成（入力データを含む完全なプロンプト）
        let promptStart = CFAbsoluteTimeGetCurrent()
        let prompt = PromptTemplateGenerator.generatePrompt(for: pattern, language: language, inputData: text)
        let promptTime = CFAbsoluteTimeGetCurrent() - promptStart
        log.debug("📝 プロンプト生成完了 - プロンプト文字数: \(prompt.count), 処理時間: \(String(format: "%.3f", promptTime))秒")
        
        // 抽出処理実行
        let aiStart = CFAbsoluteTimeGetCurrent()
        log.info("🤖 AI抽出処理を実行")
        
        // @GenerableマクロによりAccountInfoは自動的にGenerableプロトコルに準拠
        let stream = session.streamResponse(to: prompt, generating: AccountInfo.self)
        var partialResultCount = 0
        
        // ストリーミング中の部分結果を処理
        for try await _ in stream {
            partialResultCount += 1
            log.debug("🔄 部分的な結果を受信 [番号: \(partialResultCount)]")
        }
        
        // 最終結果を収集
        let collectStart = CFAbsoluteTimeGetCurrent()
        log.info("🎯 ストリーミング完了 - 最終結果を収集中...")
        let finalResult = try await stream.collect()
        let collectTime = CFAbsoluteTimeGetCurrent() - collectStart
        log.info("⏱️  結果収集時間: \(String(format: "%.3f", collectTime))秒")
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let aiTime = CFAbsoluteTimeGetCurrent() - aiStart
        log.info("✅ AI抽出処理成功 - 総処理時間: \(String(format: "%.3f", duration))秒, AI処理時間: \(String(format: "%.3f", aiTime))秒, 部分結果数: \(partialResultCount)")
        
        return (finalResult.content, duration)
    }
    
    /// JSON形式での抽出処理
    @MainActor
    private func performJSONExtraction(session: LanguageModelSession, text: String, startTime: CFAbsoluteTime, language: PromptLanguage, pattern: ExperimentPattern) async throws -> (AccountInfo, TimeInterval) {
        log.debug("🔍 JSON形式抽出処理開始")
        
        // プロンプトを生成（入力データを含む完全なプロンプト）
        let promptStart = CFAbsoluteTimeGetCurrent()
        let prompt = PromptTemplateGenerator.generatePrompt(for: pattern, language: language, inputData: text)
        let promptTime = CFAbsoluteTimeGetCurrent() - promptStart
        log.debug("📝 プロンプト生成完了 - プロンプト文字数: \(prompt.count), 処理時間: \(String(format: "%.3f", promptTime))秒")
        log.info("🔍 生成されたプロンプト内容:")
        log.info("\(prompt)")
        
        // 抽出処理実行
        let aiStart = CFAbsoluteTimeGetCurrent()
        log.info("🤖 AI抽出処理を実行（JSON形式）")
        
        let stream = session.streamResponse(to: prompt)
        let response = try await stream.collect()
        let aiTime = CFAbsoluteTimeGetCurrent() - aiStart
        log.info("⏱️  AI処理時間: \(String(format: "%.3f", aiTime))秒")
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // JSONをパースしてAccountInfoに変換
        let accountInfo = try parseJSONResponse(response.content, duration: duration)
        
        log.info("✅ JSON抽出処理成功 - 処理時間: \(String(format: "%.3f", duration))秒")
        
        return (accountInfo, duration)
    }
    
    /// YAML形式での抽出処理
    @MainActor
    private func performYAMLExtraction(session: LanguageModelSession, text: String, startTime: CFAbsoluteTime, language: PromptLanguage, pattern: ExperimentPattern) async throws -> (AccountInfo, TimeInterval) {
        log.debug("🔍 YAML形式抽出処理開始")
        
        // プロンプトを生成（入力データを含む完全なプロンプト）
        let promptStart = CFAbsoluteTimeGetCurrent()
        let prompt = PromptTemplateGenerator.generatePrompt(for: pattern, language: language, inputData: text)
        let promptTime = CFAbsoluteTimeGetCurrent() - promptStart
        log.debug("📝 プロンプト生成完了 - プロンプト文字数: \(prompt.count), 処理時間: \(String(format: "%.3f", promptTime))秒")
        
        // 抽出処理実行
        let aiStart = CFAbsoluteTimeGetCurrent()
        log.info("🤖 AI抽出処理を実行（YAML形式）")
        
        let stream = session.streamResponse(to: prompt)
        let response = try await stream.collect()
        let aiTime = CFAbsoluteTimeGetCurrent() - aiStart
        log.info("⏱️  AI処理時間: \(String(format: "%.3f", aiTime))秒")
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // YAMLをパースしてAccountInfoに変換
        let accountInfo = try parseYAMLResponse(response.content, duration: duration)
        
        log.info("✅ YAML抽出処理成功 - 処理時間: \(String(format: "%.3f", duration))秒")
        
        return (accountInfo, duration)
    }
    
    /// プロンプトテンプレートを読み込み
    private func loadPromptTemplate(for method: ExtractionMethod, language: PromptLanguage) throws -> String {
        let fileName: String
        switch method {
        case .json:
            fileName = language == .japanese ? "json_prompt" : "json_prompt_en"
        case .yaml:
            fileName = language == .japanese ? "yaml_prompt" : "yaml_prompt_en"
        case .generable:
            return makePrompt(language: language.rawValue)
        }
        
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "txt") else {
            log.error("❌ プロンプトファイルが見つかりません: \(fileName).txt")
            log.error("📝 検索パス: Bundle.module")
            throw ExtractionError.promptTemplateNotFound
        }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        log.debug("📝 プロンプトテンプレート読み込み完了: \(fileName).txt")
        return content
    }
    
    /// JSONレスポンスをパース
    private func parseJSONResponse(_ response: String, duration: TimeInterval) throws -> AccountInfo {
        log.debug("🔍 JSONレスポンス解析開始")
        log.debug("📝 生レスポンス（最初の500文字）: \(String(response.prefix(500)))")
        
        // JSONの開始と終了を検索
        let jsonStart = response.firstIndex(of: "{")
        let jsonEnd = response.lastIndex(of: "}")
        
        guard let start = jsonStart, let end = jsonEnd, start < end else {
            log.error("❌ JSON形式が見つかりません")
            log.error("📝 レスポンス全体: \(response)")
            log.error("📝 レスポンス文字数: \(response.count)")
            log.error("📝 レスポンスに含まれる文字: \(Set(response))")
            throw ExtractionError.invalidJSONFormat(aiResponse: response)
        }
        
        let jsonString = String(response[start...end])
        log.debug("📝 抽出されたJSON: \(jsonString)")
        
        guard let data = jsonString.data(using: .utf8) else {
            log.error("❌ JSON文字列の変換に失敗")
            log.error("📝 変換対象文字列: \(jsonString)")
            throw ExtractionError.invalidJSONFormat(aiResponse: jsonString)
        }
        
        do {
            let decoder = JSONDecoder()
            let accountInfo = try decoder.decode(AccountInfo.self, from: data)
            log.debug("✅ JSON解析完了")
            return accountInfo
        } catch let decodingError as DecodingError {
            log.error("❌ JSONデコードエラー: \(decodingError)")
            log.error("📝 デコード対象データ: \(String(data: data, encoding: .utf8) ?? "変換失敗")")
            
            switch decodingError {
            case .typeMismatch(let type, let context):
                log.error("📝 型不一致 - 期待型: \(type), パス: \(context.codingPath)")
                log.error("📝 コンテキスト: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                log.error("📝 値が見つからない - 型: \(type), パス: \(context.codingPath)")
                log.error("📝 コンテキスト: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                log.error("📝 キーが見つからない - キー: \(key.stringValue), パス: \(context.codingPath)")
                log.error("📝 コンテキスト: \(context.debugDescription)")
            case .dataCorrupted(let context):
                log.error("📝 データ破損 - パス: \(context.codingPath)")
                log.error("📝 コンテキスト: \(context.debugDescription)")
            @unknown default:
                log.error("📝 不明なデコードエラー")
            }
            
            throw ExtractionError.invalidJSONFormat(aiResponse: jsonString)
        } catch {
            log.error("❌ 予期しないエラー: \(error)")
            log.error("📝 エラータイプ: \(type(of: error))")
            throw ExtractionError.invalidJSONFormat(aiResponse: jsonString)
        }
    }
    
    /// YAMLレスポンスをパース
    private func parseYAMLResponse(_ response: String, duration: TimeInterval) throws -> AccountInfo {
        log.debug("🔍 YAMLレスポンス解析開始")
        log.debug("📝 生レスポンス（最初の500文字）: \(String(response.prefix(500)))")
        
        // YAMLの開始を検索（最初のキーから）
        let yamlStart = response.firstIndex(of: "t") // "title:"の開始
        let yamlEnd = response.lastIndex(of: "\n")
        
        guard let start = yamlStart, let end = yamlEnd, start < end else {
            log.error("❌ YAML形式が見つかりません")
            log.error("📝 レスポンス全体: \(response)")
            log.error("📝 レスポンス文字数: \(response.count)")
            log.error("📝 レスポンスに含まれる文字: \(Set(response))")
            log.error("📝 't'の位置: \(yamlStart?.utf16Offset(in: response) ?? -1)")
            log.error("📝 最後の改行の位置: \(yamlEnd?.utf16Offset(in: response) ?? -1)")
            throw ExtractionError.invalidYAMLFormat
        }
        
        let yamlString = String(response[start...end])
        log.debug("📝 抽出されたYAML: \(yamlString)")
        
        do {
            // YAMLをJSONに変換してからAccountInfoにデコード
            let accountInfo = try parseYAMLToAccountInfo(yamlString)
            log.debug("✅ YAML解析完了")
            return accountInfo
        } catch {
            log.error("❌ YAML解析エラー: \(error)")
            log.error("📝 エラータイプ: \(type(of: error))")
            log.error("📝 解析対象YAML: \(yamlString)")
            log.error("📝 YAML行数: \(yamlString.components(separatedBy: .newlines).count)")
            throw ExtractionError.invalidYAMLFormat
        }
    }
    
    /// YAML文字列をAccountInfoに変換
    private func parseYAMLToAccountInfo(_ yamlString: String) throws -> AccountInfo {
        log.debug("🔍 YAML文字列解析開始")
        log.debug("📝 YAML文字列: \(yamlString)")
        
        var title: String?
        var userID: String?
        var password: String?
        var url: String?
        var note: String?
        var host: String?
        var port: Int?
        var authKey: String?
        var confidence: Double?
        
        let lines = yamlString.components(separatedBy: .newlines)
        log.debug("📝 YAML行数: \(lines.count)")
        
        var parsedFields: [String: String] = [:]
        var parseErrors: [String] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") else { 
                log.debug("📝 行\(lineIndex + 1) スキップ: \(trimmedLine)")
                continue 
            }
            
            let components = trimmedLine.components(separatedBy: ":")
            guard components.count >= 2 else { 
                log.warning("⚠️ 行\(lineIndex + 1) 形式不正: \(trimmedLine)")
                parseErrors.append("行\(lineIndex + 1): コロンが不足 - \(trimmedLine)")
                continue 
            }
            
            let key = components[0].trimmingCharacters(in: .whitespaces)
            let value = components[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
            
            log.debug("📝 行\(lineIndex + 1) 解析: key='\(key)', value='\(value)'")
            
            // null値の処理
            if value == "null" || value.isEmpty {
                log.debug("📝 行\(lineIndex + 1) null値スキップ")
                continue
            }
            
            // 値の前後のクォートを除去
            let cleanValue = value.hasPrefix("\"") && value.hasSuffix("\"") ? 
                String(value.dropFirst().dropLast()) : value
            
            log.debug("📝 行\(lineIndex + 1) クリーン値: '\(cleanValue)'")
            
            switch key {
            case "title":
                title = cleanValue
                parsedFields["title"] = cleanValue
            case "userID":
                userID = cleanValue
                parsedFields["userID"] = cleanValue
            case "password":
                password = cleanValue
                parsedFields["password"] = cleanValue
            case "url":
                url = cleanValue
                parsedFields["url"] = cleanValue
            case "note":
                note = cleanValue
                parsedFields["note"] = cleanValue
            case "host":
                host = cleanValue
                parsedFields["host"] = cleanValue
            case "port":
                if let portValue = Int(cleanValue) {
                    port = portValue
                    parsedFields["port"] = String(portValue)
                } else {
                    log.warning("⚠️ 行\(lineIndex + 1) ポート番号変換失敗: '\(cleanValue)'")
                    parseErrors.append("行\(lineIndex + 1): ポート番号変換失敗 - '\(cleanValue)'")
                }
            case "authKey":
                authKey = cleanValue
                parsedFields["authKey"] = cleanValue
            case "confidence":
                if let confidenceValue = Double(cleanValue) {
                    confidence = confidenceValue
                    parsedFields["confidence"] = String(confidenceValue)
                } else {
                    log.warning("⚠️ 行\(lineIndex + 1) 信頼度変換失敗: '\(cleanValue)'")
                    parseErrors.append("行\(lineIndex + 1): 信頼度変換失敗 - '\(cleanValue)'")
                }
            default:
                log.warning("⚠️ 行\(lineIndex + 1) 未知のキー: '\(key)'")
                parseErrors.append("行\(lineIndex + 1): 未知のキー - '\(key)'")
                continue
            }
        }
        
        log.debug("📝 解析結果フィールド: \(parsedFields)")
        if !parseErrors.isEmpty {
            log.warning("⚠️ 解析エラー: \(parseErrors)")
        }
        
        let accountInfo = AccountInfo(
            title: title,
            userID: userID,
            password: password,
            url: url,
            note: note,
            host: host,
            port: port,
            authKey: authKey,
            confidence: confidence
        )
        
        log.debug("✅ YAML文字列解析完了 - 抽出フィールド数: \(accountInfo.extractedFieldsCount)")
        return accountInfo
    }
    
    /// プロンプトを生成
    private func makePrompt(language: String) -> String {
        log.debug("📝 プロンプト生成 - 言語: \(language)")
        
        switch language {
        case "ja":
            return """
            利用者の入力情報からアカウントに関する情報を抽出してください。
             
            制約:
              - 抽出できなかった項目はnilを設定すること
              - 備忘録(note)には、アカウントの用途や注意事項などの補足情報を要約して記載すること
              - 鍵情報(authKey)は、先頭行(BEGIN)と末尾行(END)を含む完全な文字列で出力すること
            
            利用者の入力情報:
            """
            
        case "en":
            return """
            Analyze and extract account-related information from the following text.
            
            Constraints:
              - Set any fields that cannot be extracted to nil
              - For the note field, summarize the account's purpose and any important details
              - For the authKey field, output the complete string including the BEGIN and END lines of the key
            
            Text:
            """
            
        default:
            log.warning("⚠️ 未対応の言語: \(language) - 英語プロンプトを使用")
            return makePrompt(language: "en")
        }
    }
    
    /// メモリ使用量取得
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // MB
        }
        return 0.0
    }
}
