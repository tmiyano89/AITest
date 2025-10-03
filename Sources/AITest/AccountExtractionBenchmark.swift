import Foundation
import os.log
import FoundationModels

/// @ai[2024-12-19 16:00] Account情報抽出の性能測定ベンチマーク
/// FoundationModelsを使用したAccount情報抽出の性能を詳細に測定
@available(iOS 26.0, macOS 26.0, *)
public class AccountExtractionBenchmark: ObservableObject {
    private let logger = Logger(subsystem: "com.aitest.benchmark", category: "AccountExtractionBenchmark")
    private let extractor = AccountExtractor()
    
    /// テスト用のサンプルデータ（フォールバック用）
    private let sampleTexts = [
        "GitHub\nUsername: john_doe\nPassword: mySecretPassword123\nURL: https://github.com/login",
        "SSH Server\nHost: 192.168.1.100\nPort: 22\nUsername: admin\nKey: -----BEGIN OPENSSH PRIVATE KEY-----\nMIIEpAIBAAKCAQEA...\n-----END OPENSSH PRIVATE KEY-----",
        "Database Server\nHost: db.example.com\nPort: 5432\nUsername: postgres\nPassword: dbPassword123\nNote: Production database, backup daily",
        "Web Application\nURL: https://app.example.com\nUsername: user@example.com\nPassword: appPassword456\nNote: Admin panel access, 2FA enabled"
    ]
    
    /// テストデータファイルのパス
    private let testDataPaths = [
        "Tests/TestData/Chat/Level1_Basic.txt",
        "Tests/TestData/Chat/Level2_General.txt", 
        "Tests/TestData/Chat/Level3_Complex.txt",
        "Tests/TestData/Contract/Level1_Basic.txt",
        "Tests/TestData/Contract/Level2_General.txt",
        "Tests/TestData/Contract/Level3_Complex.txt",
        "Tests/TestData/CreditCard/Level1_Basic.txt",
        "Tests/TestData/CreditCard/Level2_General.txt",
        "Tests/TestData/CreditCard/Level3_Complex.txt",
        "Tests/TestData/VoiceRecognition/Level1_Basic.txt",
        "Tests/TestData/VoiceRecognition/Level2_General.txt",
        "Tests/TestData/VoiceRecognition/Level3_Complex.txt",
        "Tests/TestData/PasswordManager/Level1_Basic.txt",
        "Tests/TestData/PasswordManager/Level2_General.txt",
        "Tests/TestData/PasswordManager/Level3_Complex.txt"
    ]
    
    /// ベンチマーク結果
    // @ai[2024-12-19 17:00] ビルドエラー修正: concurrencyエラーを修正
    // エラー: main actor-isolated property 'results' can not be mutated from a nonisolated context
    // エラー: non-Sendable type 'AccountExtractionBenchmark' cannot be sent into main actor-isolated context
    // エラー: non-Sendable type '[AccountExtractionResult]' of property 'results' cannot exit main actor-isolated context
    @Published public var results: [AccountExtractionResult] = []
    @Published public var isRunning = false
    
    /// デフォルト初期化子
    public init() {
        // デフォルトの初期化
    }
    
    /// ベンチマーク実行
    /// @ai[2024-12-19 16:00] Account情報抽出の包括的性能測定
    /// 目的: FoundationModelsの性能を多角的に評価
    /// 背景: 推論時間、メモリ使用量、精度、スループットを測定
    /// 意図: 最適化の指針を提供し、性能ボトルネックを特定
    @MainActor
    public func runBenchmark() async throws {
        logger.info("🚀 Account情報抽出ベンチマークを開始")
        isRunning = true
        results = []
        
        defer {
            isRunning = false
            logger.info("✅ Account情報抽出ベンチマーク完了")
        }
        
        // AI利用可能性の事前チェック
        logger.info("🔍 AI利用可能性チェック開始")
        guard await checkAIAvailability() else {
            logger.error("❌ AI機能が利用できません - ベンチマークを実行できません")
            throw BenchmarkError.aiNotAvailable
        }
        logger.info("✅ AI利用可能性チェック完了")
        
        do {
            // テキスト抽出の性能測定
            logger.info("📝 テキスト抽出性能測定を開始")
            let textResults = try await measureTextExtraction()
            results.append(contentsOf: textResults)
            logger.info("✅ テキスト抽出性能測定完了 - 結果数: \(textResults.count)")
            
            // 統計情報の計算
            let statistics = calculateStatistics(from: results)
            logger.info("📊 統計情報計算完了")
            logger.info("平均抽出時間: \(String(format: "%.3f", statistics.averageExtractionTime))秒")
            logger.info("平均メモリ使用量: \(String(format: "%.1f", statistics.averageMemoryUsage))MB")
            logger.info("平均信頼度: \(String(format: "%.2f", statistics.averageConfidence))")
            
        } catch {
            logger.error("❌ ベンチマーク実行中にエラー: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// テストデータファイルを読み込む
    @MainActor
    private func loadTestDataFiles() async -> [String] {
        var testTexts: [String] = []
        
        for path in testDataPaths {
            do {
                let fullPath = "/Users/t.miyano/repos/AITest/\(path)"
                let content = try String(contentsOfFile: fullPath, encoding: .utf8)
                testTexts.append(content)
                logger.info("✅ テストデータファイル読み込み成功: \(path)")
            } catch {
                logger.warning("⚠️ テストデータファイル読み込み失敗: \(path) - \(error.localizedDescription)")
            }
        }
        
        return testTexts
    }
    
    /// テキスト抽出の性能測定
    @MainActor
    private func measureTextExtraction() async throws -> [AccountExtractionResult] {
        // テストデータファイルを読み込む
        let testTexts = await loadTestDataFiles()
        
        if testTexts.isEmpty {
            logger.warning("⚠️ テストデータファイルが読み込めませんでした。サンプルデータを使用します")
            return try await measureSampleTexts()
        } else {
            logger.info("✅ \(testTexts.count)個のテストデータファイルを読み込みました")
            return try await measureTestDataTexts(testTexts: testTexts)
        }
    }
    
    /// サンプルテキストの性能測定
    @MainActor
    private func measureSampleTexts() async throws -> [AccountExtractionResult] {
        var results: [AccountExtractionResult] = []
        
        for (index, text) in sampleTexts.enumerated() {
            logger.info("🔍 サンプル \(index + 1)/\(self.sampleTexts.count) の処理を開始")
            
            do {
                let (accountInfo, metrics) = try await extractor.extractFromText(text)
                
                let result = AccountExtractionResult(
                    id: UUID(),
                    inputType: .text,
                    inputLength: text.count,
                    accountInfo: accountInfo,
                    metrics: metrics,
                    timestamp: Date(),
                    success: true
                )
                
                results.append(result)
                
                logger.info("✅ サンプル \(index + 1) 完了 - 抽出時間: \(String(format: "%.3f", metrics.extractionTime))秒, フィールド数: \(accountInfo.extractedFieldsCount)")
                
            } catch {
                logger.error("❌ サンプル \(index + 1) でエラー: \(error.localizedDescription)")
                
                let result = AccountExtractionResult(
                    id: UUID(),
                    inputType: .text,
                    inputLength: text.count,
                    accountInfo: nil,
                    metrics: nil,
                    timestamp: Date(),
                    success: false,
                    error: error.localizedDescription
                )
                
                results.append(result)
            }
            
            // 処理間の間隔を空ける（システム負荷軽減）
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        }
        
        return results
    }
    
    /// テストデータテキストの性能測定
    @MainActor
    private func measureTestDataTexts(testTexts: [String]) async throws -> [AccountExtractionResult] {
        var results: [AccountExtractionResult] = []
        
        for (index, text) in testTexts.enumerated() {
            logger.info("🔍 テストデータ \(index + 1)/\(testTexts.count) の処理を開始")
            
            do {
                let (accountInfo, metrics) = try await extractor.extractFromText(text)
                
                let result = AccountExtractionResult(
                    id: UUID(),
                    inputType: .text,
                    inputLength: text.count,
                    accountInfo: accountInfo,
                    metrics: metrics,
                    timestamp: Date(),
                    success: true
                )
                
                results.append(result)
                
                logger.info("✅ テストデータ \(index + 1) 完了 - 抽出時間: \(String(format: "%.3f", metrics.extractionTime))秒, フィールド数: \(accountInfo.extractedFieldsCount)")
                
            } catch {
                logger.error("❌ テストデータ \(index + 1) でエラー: \(error.localizedDescription)")
                
                let result = AccountExtractionResult(
                    id: UUID(),
                    inputType: .text,
                    inputLength: text.count,
                    accountInfo: nil,
                    metrics: nil,
                    timestamp: Date(),
                    success: false,
                    error: error.localizedDescription
                )
                
                results.append(result)
            }
            
            // 処理間の間隔を空ける（システム負荷軽減）
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        }
        
        return results
    }
    
    /// 統計情報を計算
    private func calculateStatistics(from results: [AccountExtractionResult]) -> AccountExtractionStatistics {
        let successfulResults = results.filter { $0.success && $0.metrics != nil }
        
        guard !successfulResults.isEmpty else {
            return AccountExtractionStatistics(
                totalTests: results.count,
                successfulTests: 0,
                averageExtractionTime: 0,
                averageTotalTime: 0,
                averageMemoryUsage: 0,
                averageConfidence: 0,
                averageExtractedFields: 0,
                extractionEfficiency: 0,
                memoryEfficiency: 0
            )
        }
        
        let extractionTimes = successfulResults.compactMap { $0.metrics?.extractionTime }
        let totalTimes = successfulResults.compactMap { $0.metrics?.totalTime }
        let memoryUsages = successfulResults.compactMap { $0.metrics?.memoryUsed }
        let confidences = successfulResults.compactMap { $0.metrics?.confidence }
        let extractedFields = successfulResults.compactMap { $0.accountInfo?.extractedFieldsCount }
        
        let averageExtractionTime = extractionTimes.reduce(0, +) / Double(extractionTimes.count)
        let averageTotalTime = totalTimes.reduce(0, +) / Double(totalTimes.count)
        let averageMemoryUsage = memoryUsages.reduce(0, +) / Double(memoryUsages.count)
        let averageConfidence = confidences.reduce(0, +) / Double(confidences.count)
        let averageExtractedFields = Double(extractedFields.reduce(0, +)) / Double(extractedFields.count)
        
        let extractionEfficiency = averageExtractedFields / averageExtractionTime
        let memoryEfficiency = averageExtractedFields / averageMemoryUsage
        
        return AccountExtractionStatistics(
            totalTests: results.count,
            successfulTests: successfulResults.count,
            averageExtractionTime: averageExtractionTime,
            averageTotalTime: averageTotalTime,
            averageMemoryUsage: averageMemoryUsage,
            averageConfidence: averageConfidence,
            averageExtractedFields: averageExtractedFields,
            extractionEfficiency: extractionEfficiency,
            memoryEfficiency: memoryEfficiency
        )
    }
    
    /// 結果をCSV形式でエクスポート
    public func exportResults() async throws -> URL {
        logger.info("📄 結果をCSV形式でエクスポート")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "account_extraction_benchmark_\(Date().timeIntervalSince1970).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        var csvContent = "ID,Input Type,Input Length,Success,Extraction Time,Total Time,Memory Used,Confidence,Extracted Fields,Account Type,Error\n"
        
        for result in results {
            let extractionTime = result.metrics?.extractionTime ?? 0
            let totalTime = result.metrics?.totalTime ?? 0
            let memoryUsed = result.metrics?.memoryUsed ?? 0
            let confidence = result.metrics?.confidence ?? 0
            let extractedFields = result.accountInfo?.extractedFieldsCount ?? 0
            let accountType = result.accountInfo?.accountType.rawValue ?? ""
            let error = result.error ?? ""
            
            csvContent += "\(result.id),\(result.inputType.rawValue),\(result.inputLength),\(result.success),\(extractionTime),\(totalTime),\(memoryUsed),\(confidence),\(extractedFields),\(accountType),\"\(error)\"\n"
        }
        
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        logger.info("✅ 結果エクスポート完了: \(fileURL.path)")
        
        return fileURL
    }
    
    /// AI利用可能性をチェック（システムAPI使用）
    /// @ai[2024-12-19 16:30] Apple公式APIを使用したAI利用可能性チェック
    /// 目的: ベンチマーク実行前にAI機能が利用可能かどうかを確認
    /// 背景: Apple公式ドキュメントに従った正確な実装
    /// 意図: 利用不可の場合は早期にエラーを出力して処理を終了
    @MainActor
    private func checkAIAvailability() async -> Bool {
        // FoundationModelsは既に利用可能（iOS 26+、macOS 26+）
        
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
    
    /// ベンチマークをリセット
    // @ai[2024-12-19 17:00] ビルドエラー修正: concurrencyエラーを修正
    // エラー: main actor-isolated property 'results' can not be mutated from a nonisolated context
    @MainActor
    public func reset() {
        results = []
        isRunning = false
        logger.info("🔄 ベンチマーク結果をリセット")
    }
}

/// Account情報抽出結果
@available(iOS 26.0, macOS 26.0, *)
public struct AccountExtractionResult: Identifiable, Codable {
    public let id: UUID
    public let inputType: InputType
    public let inputLength: Int
    public let accountInfo: AccountInfo?
    public let metrics: ExtractionMetrics?
    public let timestamp: Date
    public let success: Bool
    public let error: String?
    
    public init(
        id: UUID,
        inputType: InputType,
        inputLength: Int,
        accountInfo: AccountInfo?,
        metrics: ExtractionMetrics?,
        timestamp: Date,
        success: Bool,
        error: String? = nil
    ) {
        self.id = id
        self.inputType = inputType
        self.inputLength = inputLength
        self.accountInfo = accountInfo
        self.metrics = metrics
        self.timestamp = timestamp
        self.success = success
        self.error = error
    }
}

/// 入力タイプ
public enum InputType: String, CaseIterable, Codable {
    case text = "Text"
}

/// Account情報抽出統計
public struct AccountExtractionStatistics: Codable {
    public let totalTests: Int
    public let successfulTests: Int
    public let averageExtractionTime: Double
    public let averageTotalTime: Double
    public let averageMemoryUsage: Double
    public let averageConfidence: Double
    public let averageExtractedFields: Double
    public let extractionEfficiency: Double
    public let memoryEfficiency: Double
    
    /// 成功率
    public var successRate: Double {
        guard totalTests > 0 else { return 0 }
        return Double(successfulTests) / Double(totalTests)
    }
}

/// ベンチマークエラー
public enum BenchmarkError: LocalizedError {
    case aiNotAvailable
    case extractionFailed(String)
    case invalidInput
    case systemError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .aiNotAvailable:
            return "AI機能が利用できません。デバイス要件とApple Intelligenceの設定を確認してください。"
        case .extractionFailed(let message):
            return "抽出処理に失敗しました: \(message)"
        case .invalidInput:
            return "無効な入力データです"
        case .systemError(let error):
            return "システムエラー: \(error.localizedDescription)"
        }
    }
}
