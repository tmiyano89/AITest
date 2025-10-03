import Foundation
import os.log
import FoundationModels

/// @ai[2024-12-19 20:30] 繰り返しベンチマーククラス
/// 同じテストを複数回実行し、統計データを収集・分析
@available(iOS 26.0, macOS 26.0, *)
public class RepeatedBenchmark: ObservableObject {
    private let logger = Logger(subsystem: "com.aitest.repeatedbenchmark", category: "RepeatedBenchmark")
    private let extractor = AccountExtractor()
    
    /// 繰り返し回数（デフォル1回）
    public var repeatCount: Int = 1
    
    /// ベンチマーク結果
    @Published public var results: [RepeatedTestResult] = []
    
    /// 統計情報
    @Published public var statistics: BenchmarkStatistics?
    
    /// 実行中フラグ
    @Published public var isRunning = false
    
    public init() {}
    
    /// 繰り返しベンチマークを実行
    @MainActor
    public func runRepeatedBenchmark() async throws {
        logger.info("🔄 繰り返しベンチマーク開始 - 繰り返し回数: \(self.repeatCount)")
        isRunning = true
        results = []
        
        do {
            // テストデータを読み込み
            let testTexts = await loadTestDataFiles()
            
            if testTexts.isEmpty {
                logger.warning("⚠️ テストデータファイルが読み込めませんでした")
                throw RepeatedBenchmarkError.noTestData
            }
            
            logger.info("✅ \(testTexts.count)個のテストデータファイルを読み込みました")
            
            // 各テストデータに対して繰り返し実行
            for (testIndex, testText) in testTexts.enumerated() {
                logger.info("📝 テスト \(testIndex + 1)/\(testTexts.count) を開始")
                
                var testResults: [SingleTestResult] = []
                
                // 指定回数繰り返し実行
                for repeatIndex in 0..<self.repeatCount {
                    logger.debug("🔄 繰り返し \(repeatIndex + 1)/\(self.repeatCount)")
                    
                    do {
                        let (accountInfo, metrics) = try await extractor.extractFromText(testText)
                        
                        // 成功判定: バリデーションエラーがない場合のみ成功
                        let isSuccess = metrics.validationResult.isValid
                        
                        let result = SingleTestResult(
                            repeatIndex: repeatIndex,
                            accountInfo: accountInfo,
                            metrics: metrics,
                            success: isSuccess,
                            error: isSuccess ? nil : "バリデーションエラー: \(metrics.validationResult.warnings.count)個の警告"
                        )
                        testResults.append(result)
                        
                    } catch {
                        logger.warning("⚠️ 繰り返し \(repeatIndex + 1) でエラー: \(error.localizedDescription)")
                        let result = SingleTestResult(
                            repeatIndex: repeatIndex,
                            accountInfo: nil,
                            metrics: nil,
                            success: false,
                            error: error.localizedDescription
                        )
                        testResults.append(result)
                    }
                }
                
                // テスト結果をまとめる
                let repeatedResult = RepeatedTestResult(
                    testIndex: testIndex,
                    testText: testText,
                    results: testResults
                )
                results.append(repeatedResult)
                
                logger.info("✅ テスト \(testIndex + 1) 完了 - 成功率: \(String(format: "%.1f", repeatedResult.successRate * 100))%")
            }
            
            // 統計情報を計算
            statistics = calculateStatistics()
            
            logger.info("🎉 繰り返しベンチマーク完了")
            
        } catch {
            logger.error("❌ 繰り返しベンチマークでエラー: \(error.localizedDescription)")
            throw error
        }
        
        isRunning = false
    }
    
    /// テストデータファイルを読み込む
    @MainActor
    private func loadTestDataFiles() async -> [String] {
        let testDataPaths = [
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
        
        var testTexts: [String] = []
        
        for path in testDataPaths {
            do {
                let fullPath = "/Users/t.miyano/repos/AITest/\(path)"
                let content = try String(contentsOfFile: fullPath, encoding: .utf8)
                testTexts.append(content)
                logger.debug("✅ テストデータファイル読み込み成功: \(path)")
            } catch {
                logger.warning("⚠️ テストデータファイル読み込み失敗: \(path) - \(error.localizedDescription)")
            }
        }
        
        return testTexts
    }
    
    /// 統計情報を計算
    private func calculateStatistics() -> BenchmarkStatistics {
        let allResults = results.flatMap { $0.results }
        let successfulResults = allResults.filter { $0.success }
        
        // 基本統計
        let totalTests = allResults.count
        let successfulTests = successfulResults.count
        let successRate = totalTests > 0 ? Double(successfulTests) / Double(totalTests) : 0.0
        
        // 時間統計
        let extractionTimes = successfulResults.compactMap { $0.metrics?.extractionTime }
        let averageExtractionTime = extractionTimes.isEmpty ? 0.0 : extractionTimes.reduce(0, +) / Double(extractionTimes.count)
        let minExtractionTime = extractionTimes.min() ?? 0.0
        let maxExtractionTime = extractionTimes.max() ?? 0.0
        
        // メモリ統計
        let memoryUsages = successfulResults.compactMap { $0.metrics?.memoryUsed }
        let averageMemoryUsage = memoryUsages.isEmpty ? 0.0 : memoryUsages.reduce(0, +) / Double(memoryUsages.count)
        
        // 信頼度統計
        let confidences = successfulResults.compactMap { $0.accountInfo?.confidence }
        let averageConfidence = confidences.isEmpty ? 0.0 : confidences.reduce(0, +) / Double(confidences.count)
        
        // フィールド数統計
        let fieldCounts = successfulResults.compactMap { $0.metrics?.extractedFieldsCount }
        let averageFieldCount = fieldCounts.isEmpty ? 0.0 : Double(fieldCounts.reduce(0, +)) / Double(fieldCounts.count)
        
        // バリデーション警告統計
        let validationWarnings = successfulResults.compactMap { $0.metrics?.validationResult.warnings }.flatMap { $0 }
        let warningCounts = Dictionary(grouping: validationWarnings, by: { $0.localizedDescription })
            .mapValues { $0.count }
        
        return BenchmarkStatistics(
            totalTests: totalTests,
            successfulTests: successfulTests,
            successRate: successRate,
            averageExtractionTime: averageExtractionTime,
            minExtractionTime: minExtractionTime,
            maxExtractionTime: maxExtractionTime,
            averageMemoryUsage: averageMemoryUsage,
            averageConfidence: averageConfidence,
            averageFieldCount: averageFieldCount,
            warningCounts: warningCounts
        )
    }
}

/// 繰り返しテスト結果
@available(iOS 26.0, macOS 26.0, *)
public struct RepeatedTestResult: Codable, Identifiable {
    public let id = UUID()
    public let testIndex: Int
    public let testText: String
    public let results: [SingleTestResult]
    public let fieldAnalysis: FieldLevelAnalysis
    
    public init(testIndex: Int, testText: String, results: [SingleTestResult]) {
        self.testIndex = testIndex
        self.testText = testText
        self.results = results
        self.fieldAnalysis = FieldLevelAnalysis(results: results, testText: testText)
    }
    
    /// 成功率
    public var successRate: Double {
        let successful = results.filter { $0.success }.count
        return Double(successful) / Double(results.count)
    }
    
    /// 平均抽出時間
    public var averageExtractionTime: Double {
        let times = results.compactMap { $0.metrics?.extractionTime }
        return times.isEmpty ? 0.0 : times.reduce(0, +) / Double(times.count)
    }
    
    /// 平均信頼度
    public var averageConfidence: Double {
        let confidences = results.compactMap { $0.accountInfo?.confidence }
        return confidences.isEmpty ? 0.0 : confidences.reduce(0, +) / Double(confidences.count)
    }
    
    /// 総実行回数
    public var totalRuns: Int {
        return results.count
    }
    
    /// 成功回数
    public var successfulRuns: Int {
        return results.filter { $0.success }.count
    }
}

/// 単一テスト結果
@available(iOS 26.0, macOS 26.0, *)
public struct SingleTestResult: Codable, Identifiable {
    public let id = UUID()
    public let repeatIndex: Int
    public let accountInfo: AccountInfo?
    public let metrics: ExtractionMetrics?
    public let success: Bool
    public let error: String?
}

/// ベンチマーク統計情報
@available(iOS 26.0, macOS 26.0, *)
public struct BenchmarkStatistics: Codable {
    public let totalTests: Int
    public let successfulTests: Int
    public let successRate: Double
    public let averageExtractionTime: Double
    public let minExtractionTime: Double
    public let maxExtractionTime: Double
    public let averageMemoryUsage: Double
    public let averageConfidence: Double
    public let averageFieldCount: Double
    public let warningCounts: [String: Int]
}

/// 繰り返しベンチマークエラー
@available(iOS 26.0, macOS 26.0, *)
public enum RepeatedBenchmarkError: LocalizedError {
    case noTestData
    case extractionFailed
    
    public var errorDescription: String? {
        switch self {
        case .noTestData:
            return "テストデータが見つかりません"
        case .extractionFailed:
            return "抽出処理に失敗しました"
        }
    }
}
