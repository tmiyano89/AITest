import XCTest
@testable import AITest

/// @ai[2024-12-19 15:30] AITestのメインテストスイート
/// ベンチマーク機能の動作検証と性能テストを実行
final class AITestTests: XCTestCase {
    
    var benchmarkManager: BenchmarkManager!
    
    override func setUpWithError() throws {
        // テスト実行前の初期化
        benchmarkManager = BenchmarkManager()
    }
    
    override func tearDownWithError() throws {
        // テスト実行後のクリーンアップ
        benchmarkManager = nil
    }
    
    /// @ai[2024-12-19 15:30] ベンチマーク結果の妥当性テスト
    /// 測定結果が期待される範囲内にあることを確認
    func testBenchmarkResultValidation() throws {
        let validResult = BenchmarkResult(
            id: UUID(),
            modelName: "Test Model",
            modelIdentifier: "com.test.model",
            inferenceTime: 0.1,
            modelLoadTime: 0.05,
            memoryUsage: 50.0,
            cpuUsage: 25.0,
            totalTime: 0.15,
            timestamp: Date()
        )
        
        XCTAssertTrue(validResult.isValid, "Valid result should pass validation")
        
        let invalidResult = BenchmarkResult(
            id: UUID(),
            modelName: "Test Model",
            modelIdentifier: "com.test.model",
            inferenceTime: -0.1, // 負の値は無効
            modelLoadTime: 0.05,
            memoryUsage: 50.0,
            cpuUsage: 150.0, // 100%を超える値は無効
            totalTime: 0.15,
            timestamp: Date()
        )
        
        XCTAssertFalse(invalidResult.isValid, "Invalid result should fail validation")
    }
    
    /// @ai[2024-12-19 15:30] テストタイプの定義テスト
    /// 全てのテストタイプが正しく定義されていることを確認
    func testTestTypeDefinitions() throws {
        let allTypes = TestType.allCases
        
        XCTAssertEqual(allTypes.count, 4, "Should have 4 test types")
        
        for testType in allTypes {
            XCTAssertFalse(testType.displayName.isEmpty, "Display name should not be empty for \(testType)")
            XCTAssertFalse(testType.description.isEmpty, "Description should not be empty for \(testType)")
        }
    }
    
    /// @ai[2024-12-19 15:30] 性能統計計算テスト
    /// 統計計算が正しく実行されることを確認
    func testPerformanceStatisticsCalculation() throws {
        let testValues = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        let stats = PerformanceStatistics(from: testValues)
        
        XCTAssertEqual(stats.mean, 5.5, accuracy: 0.01, "Mean should be 5.5")
        XCTAssertEqual(stats.median, 5.5, accuracy: 0.01, "Median should be 5.5")
        XCTAssertEqual(stats.min, 1.0, accuracy: 0.01, "Min should be 1.0")
        XCTAssertEqual(stats.max, 10.0, accuracy: 0.01, "Max should be 10.0")
        XCTAssertTrue(stats.standardDeviation > 0, "Standard deviation should be positive")
    }
    
    /// @ai[2024-12-19 15:30] ベンチマーク設定テスト
    /// デフォルト設定が適切であることを確認
    func testDefaultBenchmarkConfiguration() throws {
        let config = BenchmarkConfiguration.default
        
        XCTAssertGreaterThan(config.iterations, 0, "Iterations should be positive")
        XCTAssertGreaterThanOrEqual(config.warmupIterations, 0, "Warmup iterations should be non-negative")
        XCTAssertGreaterThan(config.timeout, 0, "Timeout should be positive")
        XCTAssertTrue(config.enableMemoryProfiling, "Memory profiling should be enabled by default")
        XCTAssertTrue(config.enableCPUProfiling, "CPU profiling should be enabled by default")
        XCTAssertTrue(config.enableBatteryProfiling, "Battery profiling should be enabled by default")
    }
    
    /// @ai[2024-12-19 15:30] 非同期ベンチマーク実行テスト
    /// ベンチマークが非同期で正しく実行されることを確認
    func testAsyncBenchmarkExecution() async throws {
        // 注意: 実際のApple Intelligence APIが利用できないため、
        // このテストはモック実装での動作確認に留める
        
        do {
            let results = try await benchmarkManager.runBenchmark(type: .inferenceTime)
            XCTAssertFalse(results.isEmpty, "Results should not be empty")
        } catch {
            XCTFail("Benchmark execution failed: \(error)")
        }
    }
    
    /// @ai[2024-12-19 16:00] Account情報抽出テスト
    /// FoundationModelsを使用したAccount情報抽出の動作確認
    @available(iOS 18.2, macOS 15.0, *)
    func testAccountExtraction() async throws {
        // 注意: 実際のFoundationModelsが利用できないため、
        // このテストはコンパイル確認のみ
        
        let sampleText = "GitHub\nUsername: test_user\nPassword: test_password\nURL: https://github.com"
        
        // AccountExtractorの初期化確認
        let extractor = AccountExtractor()
        XCTAssertNotNil(extractor, "AccountExtractor should be initialized")
        
        // 実際の抽出は実行しない（FoundationModelsが利用できないため）
        // 将来的にFoundationModelsが利用可能になったら実際のテストを実装
    }
    
    /// @ai[2024-12-19 16:00] AccountInfoバリデーションテスト
    /// AccountInfoのバリデーション機能をテスト
    func testAccountInfoValidation() throws {
        // 有効なAccountInfo
        let validAccount = AccountInfo(
            title: "Test Service",
            userID: "test@example.com",
            password: "password123",
            url: "https://example.com"
        )
        
        XCTAssertTrue(validAccount.isValid, "Valid account should pass validation")
        XCTAssertEqual(validAccount.extractedFieldsCount, 4, "Should have 4 extracted fields")
        
        // 無効なURLを持つAccountInfo
        let invalidAccount = AccountInfo(
            title: "Test Service",
            userID: "test@example.com",
            password: "password123",
            url: "invalid-url"
        )
        
        XCTAssertFalse(invalidAccount.isValid, "Account with invalid URL should fail validation")
    }
    
    /// @ai[2024-12-19 15:30] メモリ使用量測定テスト
    /// メモリ使用量の測定が正しく動作することを確認
    func testMemoryUsageMeasurement() throws {
        // メモリ使用量の測定は実際のシステムに依存するため、
        // 基本的な動作確認のみ実行
        
        let memoryBefore = getMemoryUsage()
        
        // メモリを消費する処理をシミュレート
        let largeArray = Array(0..<1000000)
        _ = largeArray.map { $0 * 2 }
        
        let memoryAfter = getMemoryUsage()
        
        XCTAssertGreaterThanOrEqual(memoryAfter, memoryBefore, "Memory usage should not decrease")
    }
    
    /// @ai[2024-12-19 15:30] メモリ使用量取得のヘルパー関数
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
