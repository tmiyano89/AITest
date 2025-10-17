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

/// @ai[2024-12-19 16:30] 抽出方法の列挙型
/// 目的: 複数の抽出方法を選択可能にする
/// 背景: @Generableマクロ、JSON形式、YAML形式の3つの方法を提供
/// 意図: ユーザーが最適な抽出方法を選択できるようにする
@available(iOS 26.0, macOS 26.0, *)
public enum ExtractionMethod: String, CaseIterable, Codable, Sendable {
    case generable = "generable"
    case json = "json"
    case yaml = "yaml"
    
    public var displayName: String {
        switch self {
        case .generable:
            return "@Generableマクロ"
        case .json:
            return "JSON形式"
        case .yaml:
            return "YAML形式"
        }
    }
    
    public var description: String {
        switch self {
        case .generable:
            return "FoundationModelsの@Generableマクロを使用した構造化抽出"
        case .json:
            return "JSON形式での回答を要求し、JSONDecoderでデコード"
        case .yaml:
            return "YAML形式での回答を要求し、YAMLパーサーでデコード"
        }
    }
}

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
    private let logger = Logger(subsystem: "com.aitest.extractor", category: "AccountExtractor")
    
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
        logger.info("AccountExtractor initialized")
    }
    
    /// デイニシャライザ
    deinit {
        logger.info("AccountExtractor deinitialized")
        cancel()
    }
    
    /// テキストからアカウント情報を抽出（@Generableマクロ使用）
    /// @ai[2024-12-19 16:00] 性能測定用の抽出処理
    /// 目的: FoundationModelsを使用したAccount情報抽出の性能を測定
    /// 背景: LanguageSessionModelの推論時間、メモリ使用量、精度を評価
    /// 意図: 数値的な性能データを収集し、最適化の指針を提供
    @MainActor
    public func extractFromText(_ text: String, method: ExtractionMethod = .generable, language: PromptLanguage = .japanese, pattern: ExperimentPattern = .defaultPattern) async throws -> (AccountInfo, ExtractionMetrics) {
        logger.info("🔍 [STEP 1/5] テキスト抽出処理を開始")
        let startTime = CFAbsoluteTimeGetCurrent()
        let memoryBefore = getMemoryUsage()
        
        defer { logger.info("✅ [STEP 5/5] テキスト抽出処理完了") }
        
        do {
            // AI利用可能性の事前チェック
            let aiCheckStart = CFAbsoluteTimeGetCurrent()
            logger.info("🔍 [STEP 0/5] AI利用可能性チェック")
            guard await checkAIAvailability() else {
                logger.error("❌ AI機能が利用できません")
                throw ExtractionError.aifmNotSupported
            }
            let aiCheckTime = CFAbsoluteTimeGetCurrent() - aiCheckStart
            logger.info("✅ AI利用可能性チェック完了 - 処理時間: \(String(format: "%.3f", aiCheckTime))秒")
            
            // 入力検証
            let validationStart = CFAbsoluteTimeGetCurrent()
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                logger.error("❌ 入力検証失敗: 空のテキスト")
                throw ExtractionError.invalidInput
            }
            let validationTime = CFAbsoluteTimeGetCurrent() - validationStart
            logger.info("✅ 入力テキスト検証完了 - 文字数: \(text.count), 処理時間: \(String(format: "%.3f", validationTime))秒")
            
            // セッション初期化
            let sessionStart = CFAbsoluteTimeGetCurrent()
            if session == nil {
                logger.info("🔄 セッション初期化を実行")
                try await initializeSession(pattern: pattern, language: language)
                logger.info("✅ セッション初期化完了")
            }
            let sessionTime = CFAbsoluteTimeGetCurrent() - sessionStart
            logger.info("⏱️  セッション初期化時間: \(String(format: "%.3f", sessionTime))秒")
            
            // 抽出処理実行
            let extractionStart = CFAbsoluteTimeGetCurrent()
            logger.info("🚀 AI抽出処理を開始 - 方法: \(method.displayName), 言語: \(language.displayName), パターン: \(pattern.displayName)")
            let (accountInfo, extractionTime) = try await performExtraction(from: text, method: method, language: language, pattern: pattern)
            let totalExtractionTime = CFAbsoluteTimeGetCurrent() - extractionStart
            logger.info("✅ AI抽出処理完了 - 内部処理時間: \(String(format: "%.3f", extractionTime))秒, 総処理時間: \(String(format: "%.3f", totalExtractionTime))秒")
            
            // バリデーション（警告のみ、処理は中断しない）
            let validationResult = accountInfo.validate()
            if !validationResult.isValid {
                logger.warning("⚠️ バリデーション警告: \(validationResult.warnings.count)個の警告")
                for warning in validationResult.warnings {
                    logger.warning("  - \(warning.errorDescription ?? "不明な警告")")
                }
            } else {
                logger.info("✅ 抽出結果バリデーション完了（警告なし）")
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
            
            logger.info("📊 抽出結果統計 - フィールド数: \(accountInfo.extractedFieldsCount), 信頼度: \(String(format: "%.2f", accountInfo.confidence ?? 0))")
            
            return (accountInfo, metrics)
            
        } catch {
            logger.error("❌ テキスト抽出処理でエラー: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    /// 処理をキャンセル
    public func cancel() {
        logger.info("🛑 抽出処理をキャンセル")
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
        logger.debug("🔍 AI利用可能性チェック開始（システムAPI使用）")
        
        // FoundationModelsは既に利用可能（iOS 26+、macOS 26+）
        
        // システムAPIを使用してAI利用可能性をチェック
        let systemModel = SystemLanguageModel.default
        let availability = systemModel.availability
        
        logger.info("🔍 システムAPI利用可能性チェック結果: \(String(describing: availability))")
        
        switch availability {
        case .available:
            logger.info("✅ AI利用可能（システムAPI確認済み）")
            return true
            
        case .unavailable(.appleIntelligenceNotEnabled):
            logger.error("❌ Apple Intelligenceが無効です（システムAPI確認済み）")
            logger.error("設定 > Apple Intelligence でApple Intelligenceを有効にしてください")
            return false
            
        case .unavailable(.deviceNotEligible):
            logger.error("❌ このデバイスではAIモデルを利用できません（システムAPI確認済み）")
            logger.error("iPhone 15 Pro以降、またはM1以降のMacが必要です")
            return false
            
        case .unavailable(.modelNotReady):
            logger.error("❌ AIモデルをダウンロード中です（システムAPI確認済み）")
            logger.error("モデルのダウンロードが完了するまでお待ちください")
            return false
            
        case .unavailable(let reason):
            logger.error("❌ Apple Intelligence利用不可（システムAPI確認済み）: \(String(describing: reason))")
            return false
        }
    }
    
    
    /// セッションを初期化
    @MainActor
    private func initializeSession(pattern: ExperimentPattern = .defaultPattern, language: PromptLanguage = .japanese) async throws {
        logger.debug("🔧 セッション初期化開始")
        
        // AI利用可能性をチェック
        guard await checkAIAvailability() else {
            logger.error("❌ AI機能が利用できません")
            throw ExtractionError.aifmNotSupported
        }
        
        logger.info("✅ AI利用可能性チェック完了")
        
        // FoundationModelsを使用してセッションを初期化
        let sessionInstructions = PromptTemplateGenerator.generateSessionInstructions(for: pattern, language: language)
        session = LanguageModelSession(
            instructions: Instructions {
                sessionInstructions
            }
        )
        logger.info("✅ セッション初期化完了")
    }
    
    
    
    /// 抽出処理を実行
    @MainActor
    private func performExtraction(from text: String, method: ExtractionMethod, language: PromptLanguage, pattern: ExperimentPattern) async throws -> (AccountInfo, TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        logger.debug("🔍 抽出処理開始 - 入力テキスト文字数: \(text.count)")
        
        guard let session = self.session else {
            logger.error("❌ セッションが初期化されていません")
            throw ExtractionError.languageModelUnavailable
        }
        
        // セッションは既にLanguageModelSessionとして初期化済み
        
        defer {
            logger.debug("🧹 セッションを解放")
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
    
    /// @Generableマクロを使用した抽出処理
    @MainActor
    private func performGenerableExtraction(session: LanguageModelSession, text: String, startTime: CFAbsoluteTime, language: PromptLanguage, pattern: ExperimentPattern) async throws -> (AccountInfo, TimeInterval) {
        logger.debug("🔍 @Generableマクロ抽出処理開始")
        
        // プロンプト生成
        let promptStart = CFAbsoluteTimeGetCurrent()
        let prompt = PromptTemplateGenerator.generatePrompt(for: pattern, language: language) + "\n" + text
        let promptTime = CFAbsoluteTimeGetCurrent() - promptStart
        logger.debug("📝 プロンプト生成完了 - プロンプト文字数: \(prompt.count), 処理時間: \(String(format: "%.3f", promptTime))秒")
        
        // 抽出処理実行
        let aiStart = CFAbsoluteTimeGetCurrent()
        logger.info("🤖 AI抽出処理を実行")
        
        // @GenerableマクロによりAccountInfoは自動的にGenerableプロトコルに準拠
        let stream = session.streamResponse(to: prompt, generating: AccountInfo.self)
        var partialResultCount = 0
        
        // ストリーミング中の部分結果を処理
        for try await _ in stream {
            partialResultCount += 1
            logger.debug("🔄 部分的な結果を受信 [番号: \(partialResultCount)]")
        }
        
        // 最終結果を収集
        let collectStart = CFAbsoluteTimeGetCurrent()
        logger.info("🎯 ストリーミング完了 - 最終結果を収集中...")
        let finalResult = try await stream.collect()
        let collectTime = CFAbsoluteTimeGetCurrent() - collectStart
        logger.info("⏱️  結果収集時間: \(String(format: "%.3f", collectTime))秒")
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let aiTime = CFAbsoluteTimeGetCurrent() - aiStart
        logger.info("✅ AI抽出処理成功 - 総処理時間: \(String(format: "%.3f", duration))秒, AI処理時間: \(String(format: "%.3f", aiTime))秒, 部分結果数: \(partialResultCount)")
        
        return (finalResult.content, duration)
    }
    
    /// JSON形式での抽出処理
    @MainActor
    private func performJSONExtraction(session: LanguageModelSession, text: String, startTime: CFAbsoluteTime, language: PromptLanguage, pattern: ExperimentPattern) async throws -> (AccountInfo, TimeInterval) {
        logger.debug("🔍 JSON形式抽出処理開始")
        
        // JSONプロンプトを読み込み
        let promptStart = CFAbsoluteTimeGetCurrent()
        let prompt = PromptTemplateGenerator.generatePrompt(for: pattern, language: language) + "\n" + text
        let promptTime = CFAbsoluteTimeGetCurrent() - promptStart
        logger.debug("📝 JSONプロンプト生成完了 - プロンプト文字数: \(prompt.count), 処理時間: \(String(format: "%.3f", promptTime))秒")
        
        // 抽出処理実行
        let aiStart = CFAbsoluteTimeGetCurrent()
        logger.info("🤖 AI抽出処理を実行（JSON形式）")
        
        let stream = session.streamResponse(to: prompt)
        let response = try await stream.collect()
        let aiTime = CFAbsoluteTimeGetCurrent() - aiStart
        logger.info("⏱️  AI処理時間: \(String(format: "%.3f", aiTime))秒")
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // JSONをパースしてAccountInfoに変換
        let accountInfo = try parseJSONResponse(response.content, duration: duration)
        
        logger.info("✅ JSON抽出処理成功 - 処理時間: \(String(format: "%.3f", duration))秒")
        
        return (accountInfo, duration)
    }
    
    /// YAML形式での抽出処理
    @MainActor
    private func performYAMLExtraction(session: LanguageModelSession, text: String, startTime: CFAbsoluteTime, language: PromptLanguage, pattern: ExperimentPattern) async throws -> (AccountInfo, TimeInterval) {
        logger.debug("🔍 YAML形式抽出処理開始")
        
        // YAMLプロンプトを読み込み
        let promptStart = CFAbsoluteTimeGetCurrent()
        let prompt = PromptTemplateGenerator.generatePrompt(for: pattern, language: language) + "\n" + text
        let promptTime = CFAbsoluteTimeGetCurrent() - promptStart
        logger.debug("📝 YAMLプロンプト生成完了 - プロンプト文字数: \(prompt.count), 処理時間: \(String(format: "%.3f", promptTime))秒")
        
        // 抽出処理実行
        let aiStart = CFAbsoluteTimeGetCurrent()
        logger.info("🤖 AI抽出処理を実行（YAML形式）")
        
        let stream = session.streamResponse(to: prompt)
        let response = try await stream.collect()
        let aiTime = CFAbsoluteTimeGetCurrent() - aiStart
        logger.info("⏱️  AI処理時間: \(String(format: "%.3f", aiTime))秒")
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // YAMLをパースしてAccountInfoに変換
        let accountInfo = try parseYAMLResponse(response.content, duration: duration)
        
        logger.info("✅ YAML抽出処理成功 - 処理時間: \(String(format: "%.3f", duration))秒")
        
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
            logger.error("❌ プロンプトファイルが見つかりません: \(fileName).txt")
            logger.error("📝 検索パス: Bundle.module")
            throw ExtractionError.promptTemplateNotFound
        }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        logger.debug("📝 プロンプトテンプレート読み込み完了: \(fileName).txt")
        return content
    }
    
    /// JSONレスポンスをパース
    private func parseJSONResponse(_ response: String, duration: TimeInterval) throws -> AccountInfo {
        logger.debug("🔍 JSONレスポンス解析開始")
        logger.debug("📝 生レスポンス（最初の500文字）: \(String(response.prefix(500)))")
        
        // JSONの開始と終了を検索
        let jsonStart = response.firstIndex(of: "{")
        let jsonEnd = response.lastIndex(of: "}")
        
        guard let start = jsonStart, let end = jsonEnd, start < end else {
            logger.error("❌ JSON形式が見つかりません")
            logger.error("📝 レスポンス全体: \(response)")
            logger.error("📝 レスポンス文字数: \(response.count)")
            logger.error("📝 レスポンスに含まれる文字: \(Set(response))")
            throw ExtractionError.invalidJSONFormat
        }
        
        let jsonString = String(response[start...end])
        logger.debug("📝 抽出されたJSON: \(jsonString)")
        
        guard let data = jsonString.data(using: .utf8) else {
            logger.error("❌ JSON文字列の変換に失敗")
            logger.error("📝 変換対象文字列: \(jsonString)")
            throw ExtractionError.invalidJSONFormat
        }
        
        do {
            let decoder = JSONDecoder()
            let accountInfo = try decoder.decode(AccountInfo.self, from: data)
            logger.debug("✅ JSON解析完了")
            return accountInfo
        } catch let decodingError as DecodingError {
            logger.error("❌ JSONデコードエラー: \(decodingError)")
            logger.error("📝 デコード対象データ: \(String(data: data, encoding: .utf8) ?? "変換失敗")")
            
            switch decodingError {
            case .typeMismatch(let type, let context):
                logger.error("📝 型不一致 - 期待型: \(type), パス: \(context.codingPath)")
                logger.error("📝 コンテキスト: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                logger.error("📝 値が見つからない - 型: \(type), パス: \(context.codingPath)")
                logger.error("📝 コンテキスト: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                logger.error("📝 キーが見つからない - キー: \(key.stringValue), パス: \(context.codingPath)")
                logger.error("📝 コンテキスト: \(context.debugDescription)")
            case .dataCorrupted(let context):
                logger.error("📝 データ破損 - パス: \(context.codingPath)")
                logger.error("📝 コンテキスト: \(context.debugDescription)")
            @unknown default:
                logger.error("📝 不明なデコードエラー")
            }
            
            throw ExtractionError.invalidJSONFormat
        } catch {
            logger.error("❌ 予期しないエラー: \(error)")
            logger.error("📝 エラータイプ: \(type(of: error))")
            throw ExtractionError.invalidJSONFormat
        }
    }
    
    /// YAMLレスポンスをパース
    private func parseYAMLResponse(_ response: String, duration: TimeInterval) throws -> AccountInfo {
        logger.debug("🔍 YAMLレスポンス解析開始")
        logger.debug("📝 生レスポンス（最初の500文字）: \(String(response.prefix(500)))")
        
        // YAMLの開始を検索（最初のキーから）
        let yamlStart = response.firstIndex(of: "t") // "title:"の開始
        let yamlEnd = response.lastIndex(of: "\n")
        
        guard let start = yamlStart, let end = yamlEnd, start < end else {
            logger.error("❌ YAML形式が見つかりません")
            logger.error("📝 レスポンス全体: \(response)")
            logger.error("📝 レスポンス文字数: \(response.count)")
            logger.error("📝 レスポンスに含まれる文字: \(Set(response))")
            logger.error("📝 't'の位置: \(yamlStart?.utf16Offset(in: response) ?? -1)")
            logger.error("📝 最後の改行の位置: \(yamlEnd?.utf16Offset(in: response) ?? -1)")
            throw ExtractionError.invalidYAMLFormat
        }
        
        let yamlString = String(response[start...end])
        logger.debug("📝 抽出されたYAML: \(yamlString)")
        
        do {
            // YAMLをJSONに変換してからAccountInfoにデコード
            let accountInfo = try parseYAMLToAccountInfo(yamlString)
            logger.debug("✅ YAML解析完了")
            return accountInfo
        } catch {
            logger.error("❌ YAML解析エラー: \(error)")
            logger.error("📝 エラータイプ: \(type(of: error))")
            logger.error("📝 解析対象YAML: \(yamlString)")
            logger.error("📝 YAML行数: \(yamlString.components(separatedBy: .newlines).count)")
            throw ExtractionError.invalidYAMLFormat
        }
    }
    
    /// YAML文字列をAccountInfoに変換
    private func parseYAMLToAccountInfo(_ yamlString: String) throws -> AccountInfo {
        logger.debug("🔍 YAML文字列解析開始")
        logger.debug("📝 YAML文字列: \(yamlString)")
        
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
        logger.debug("📝 YAML行数: \(lines.count)")
        
        var parsedFields: [String: String] = [:]
        var parseErrors: [String] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") else { 
                logger.debug("📝 行\(lineIndex + 1) スキップ: \(trimmedLine)")
                continue 
            }
            
            let components = trimmedLine.components(separatedBy: ":")
            guard components.count >= 2 else { 
                logger.warning("⚠️ 行\(lineIndex + 1) 形式不正: \(trimmedLine)")
                parseErrors.append("行\(lineIndex + 1): コロンが不足 - \(trimmedLine)")
                continue 
            }
            
            let key = components[0].trimmingCharacters(in: .whitespaces)
            let value = components[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
            
            logger.debug("📝 行\(lineIndex + 1) 解析: key='\(key)', value='\(value)'")
            
            // null値の処理
            if value == "null" || value.isEmpty {
                logger.debug("📝 行\(lineIndex + 1) null値スキップ")
                continue
            }
            
            // 値の前後のクォートを除去
            let cleanValue = value.hasPrefix("\"") && value.hasSuffix("\"") ? 
                String(value.dropFirst().dropLast()) : value
            
            logger.debug("📝 行\(lineIndex + 1) クリーン値: '\(cleanValue)'")
            
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
                    logger.warning("⚠️ 行\(lineIndex + 1) ポート番号変換失敗: '\(cleanValue)'")
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
                    logger.warning("⚠️ 行\(lineIndex + 1) 信頼度変換失敗: '\(cleanValue)'")
                    parseErrors.append("行\(lineIndex + 1): 信頼度変換失敗 - '\(cleanValue)'")
                }
            default:
                logger.warning("⚠️ 行\(lineIndex + 1) 未知のキー: '\(key)'")
                parseErrors.append("行\(lineIndex + 1): 未知のキー - '\(key)'")
                continue
            }
        }
        
        logger.debug("📝 解析結果フィールド: \(parsedFields)")
        if !parseErrors.isEmpty {
            logger.warning("⚠️ 解析エラー: \(parseErrors)")
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
        
        logger.debug("✅ YAML文字列解析完了 - 抽出フィールド数: \(accountInfo.extractedFieldsCount)")
        return accountInfo
    }
    
    /// プロンプトを生成
    private func makePrompt(language: String) -> String {
        logger.debug("📝 プロンプト生成 - 言語: \(language)")
        
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
            logger.warning("⚠️ 未対応の言語: \(language) - 英語プロンプトを使用")
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
