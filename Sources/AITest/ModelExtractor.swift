import Foundation
import FoundationModels

/// @ai[2025-01-19 00:30] モデル抽象化レイヤー
/// 目的: FoundationModelsと外部LLMの抽出処理を統一するインターフェース
/// 背景: コードの重複を排除し、保守性と拡張性を向上させる
/// 意図: モデル固有の実装を抽象化し、共通処理を統一

/// 抽出結果を表す構造体
/// @ai[2025-01-19 00:30] 生のレスポンスを含む抽出結果
/// 目的: AIが返した無加工の生レスポンステキストを保持
/// 背景: レスポンス分析とデバッグのため
/// 意図: モデルに依存しない統一された結果形式
@available(iOS 26.0, macOS 26.0, *)
public struct ExtractionResult: Sendable {
    public let accountInfo: AccountInfo
    public let rawResponse: String
    public let requestContent: String?
    public let extractionTime: TimeInterval
    public let method: ExtractionMethod
    
    public init(accountInfo: AccountInfo, rawResponse: String, requestContent: String? = nil, extractionTime: TimeInterval, method: ExtractionMethod) {
        self.accountInfo = accountInfo
        self.rawResponse = rawResponse
        self.requestContent = requestContent
        self.extractionTime = extractionTime
        self.method = method
    }
}

/// モデル抽出器のプロトコル
/// @ai[2025-01-19 00:30] 統一された抽出インターフェース
/// 目的: FoundationModelsと外部LLMの抽出処理を統一
/// 背景: コードの重複を排除し、保守性を向上
/// 意図: モデル固有の実装を抽象化
@available(iOS 26.0, macOS 26.0, *)
public protocol ModelExtractor {
    /// テキストからアカウント情報を抽出
    /// - Parameters:
    ///   - text: 入力テキスト
    ///   - prompt: 生成されたプロンプト
    ///   - method: 抽出方法
    /// - Returns: 抽出結果（生のレスポンスを含む）
    func extract(from text: String, prompt: String, method: ExtractionMethod) async throws -> ExtractionResult
}

/// 共通の抽出処理を提供するベースクラス
/// @ai[2025-01-19 00:30] 共通処理の実装
/// 目的: プロンプト生成、テストデータ読み込み、メトリクス作成を統一
/// 背景: コードの重複を排除し、保守性を向上
/// 意図: 共通処理を一元化
@available(iOS 26.0, macOS 26.0, *)
public class CommonExtractionProcessor {
    private let log = LogWrapper(subsystem: "com.aitest.common", category: "CommonProcessor")
    
    public init() {}
    
    /// プロンプトを生成
    /// @ai[2025-01-19 00:30] プロンプト生成の統一処理
    /// 目的: method、algo、languageのみに依存したプロンプト生成
    /// 背景: モデルやtestcase、levelに依存しない共通処理
    /// 意図: プロンプト生成の一元化
    public func generatePrompt(method: ExtractionMethod, algo: String, language: PromptLanguage) throws -> String {
        log.debug("🔧 プロンプト生成開始 - method: \(method.rawValue), algo: \(algo), language: \(language.rawValue)")
        
        // パターンを生成
        let methodSuffix = method.rawValue == "generable" ? "gen" : method.rawValue
        let patternName = "\(algo)_\(methodSuffix)"
        
        guard ExperimentPattern.allCases.contains(where: { $0.rawValue == patternName }) else {
            throw ExtractionError.invalidPattern(patternName)
        }
        
        // プロンプトテンプレートを生成（テストデータは空文字列で初期化）
        let prompt = try generatePromptTemplate(method: method, algo: algo, language: language)
        
        log.debug("✅ プロンプト生成完了 - 文字数: \(prompt.count)")
        return prompt
    }
    
    /// テストデータを読み込み
    /// @ai[2025-01-19 00:30] テストデータ読み込みの統一処理
    /// 目的: levelとtestcaseに対応するテストデータを読み込み
    /// 背景: 日本語と英語に対応した共通処理
    /// 意図: テストデータ読み込みの一元化
    public func loadTestData(testcase: String, level: Int, language: PromptLanguage) throws -> String {
        log.debug("📂 テストデータ読み込み開始 - testcase: \(testcase), level: \(level), language: \(language.rawValue)")
        
        let testcaseDir = testcase.capitalized
        let levelFile = "Level\(level)_\(level == 1 ? "Basic" : level == 2 ? "General" : "Complex").txt"
        let testDataPath = "Tests/TestData/\(testcaseDir)/\(levelFile)"
        
        guard let testData = try? String(contentsOfFile: testDataPath, encoding: .utf8) else {
            throw ExtractionError.testDataNotFound(testDataPath)
        }
        
        log.debug("✅ テストデータ読み込み完了 - 文字数: \(testData.count)")
        return testData
    }
    
    /// プロンプトを完成させる
    /// @ai[2025-01-19 00:30] プロンプト完成の統一処理
    /// 目的: ベースプロンプトにテストデータを追加して完成させる
    /// 背景: プロンプト生成とテストデータ読み込みの組み合わせ
    /// 意図: プロンプト完成処理の一元化
    public func completePrompt(basePrompt: String, testData: String) -> String {
        log.debug("🔧 プロンプト完成開始 - ベース文字数: \(basePrompt.count), テストデータ文字数: \(testData.count)")
        
        // プロンプトにテストデータを追加
        let completedPrompt = basePrompt + "\n\n添付ドキュメント:\n" + testData
        
        log.debug("✅ プロンプト完成完了 - 完成文字数: \(completedPrompt.count)")
        return completedPrompt
    }
    
    /// メトリクスを作成
    /// @ai[2025-01-19 00:30] メトリクス作成の統一処理
    /// 目的: AccountInfoからメトリクスデータを作成
    /// 背景: 抽出結果の評価指標を統一
    /// 意図: メトリクス作成の一元化
    public func createMetrics(from accountInfo: AccountInfo, extractionTime: TimeInterval, totalTime: TimeInterval) -> ExtractionMetrics {
        log.debug("📊 メトリクス作成開始 - 抽出時間: \(extractionTime), 総時間: \(totalTime)")
        
        let metrics = ExtractionMetrics(
            extractionTime: extractionTime,
            totalTime: totalTime,
            memoryUsed: getMemoryUsage(),
            textLength: 0, // 簡易実装
            extractedFieldsCount: accountInfo.extractedFieldsCount,
            confidence: accountInfo.confidence ?? 0.0,
            isValid: accountInfo.isValid,
            validationResult: accountInfo.validate()
        )
        
        log.debug("✅ メトリクス作成完了 - フィールド数: \(metrics.extractedFieldsCount), 有効: \(metrics.isValid)")
        return metrics
    }
    
    /// プロンプトテンプレートを生成
    /// @ai[2025-01-19 01:00] プロンプトテンプレート生成の実装
    /// 目的: プロンプトテンプレートファイルを読み込んで生成
    /// 背景: 無限ループを防ぐため、再帰呼び出しを避ける
    /// 意図: プロンプトテンプレート生成の一元化
    private func generatePromptTemplate(method: ExtractionMethod, algo: String, language: PromptLanguage) throws -> String {
        log.debug("📝 プロンプトテンプレート生成開始 - method: \(method.rawValue), algo: \(algo), language: \(language.rawValue)")
        
        // プロンプトファイル名を生成
        let methodSuffix = method.rawValue == "generable" ? "generable" : method.rawValue
        let algoName = algo == "abs" ? "abstract" : algo
        let fileName = "\(algoName)_\(methodSuffix)_\(language.rawValue)"
        let filePath = "Sources/AITest/Prompts/\(fileName).txt"
        
        // プロンプトファイルを読み込み
        guard let prompt = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            throw ExtractionError.promptTemplateNotFound(filePath)
        }
        
        log.debug("✅ プロンプトテンプレート生成完了 - 文字数: \(prompt.count)")
        return prompt
    }
}

/// メモリ使用量を取得
/// @ai[2025-01-19 00:30] メモリ使用量取得の共通処理
/// 目的: システムのメモリ使用量を取得
/// 背景: パフォーマンス測定のため
/// 意図: メモリ使用量測定の一元化
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
    } else {
        return 0.0
    }
}
