import Foundation

/// @ai[2024-12-19 15:30] AIモデル定義
/// Apple Intelligence Foundation Modelの基本情報を管理
struct AIModel {
    let name: String
    let identifier: String
    let version: String
    let size: Int64 // bytes
    
    init(name: String, identifier: String, version: String = "1.0", size: Int64 = 0) {
        self.name = name
        self.identifier = identifier
        self.version = version
        self.size = size
    }
}

/// @ai[2024-12-19 15:30] テストタイプ定義
/// 実行可能な性能測定の種類を定義
enum TestType: String, CaseIterable {
    case inferenceTime = "inference_time"
    case throughput = "throughput"
    case memoryEfficiency = "memory_efficiency"
    case batteryImpact = "battery_impact"
    
    var displayName: String {
        switch self {
        case .inferenceTime:
            return "推論時間"
        case .throughput:
            return "スループット"
        case .memoryEfficiency:
            return "メモリ効率"
        case .batteryImpact:
            return "バッテリー影響"
        }
    }
    
    var description: String {
        switch self {
        case .inferenceTime:
            return "単発推論の実行時間を測定"
        case .throughput:
            return "連続推論の処理能力を測定"
        case .memoryEfficiency:
            return "メモリ使用量と効率を測定"
        case .batteryImpact:
            return "バッテリー消費への影響を測定"
        }
    }
}

/// @ai[2024-12-19 15:30] ベンチマーク結果定義
/// 性能測定の結果を格納するデータ構造
struct BenchmarkResult: Identifiable {
    let id: UUID
    let modelName: String
    let modelIdentifier: String
    let inferenceTime: TimeInterval // seconds
    let modelLoadTime: TimeInterval // seconds
    let memoryUsage: Double // MB
    let cpuUsage: Double // percentage
    let totalTime: TimeInterval // seconds
    let timestamp: Date
    
    /// @ai[2024-12-19 15:30] 結果の妥当性検証
    /// 測定結果が正常な範囲内にあるかを確認
    var isValid: Bool {
        return inferenceTime > 0 &&
               modelLoadTime > 0 &&
               memoryUsage >= 0 &&
               cpuUsage >= 0 &&
               cpuUsage <= 100 &&
               totalTime > 0
    }
    
    /// @ai[2024-12-19 15:30] 結果の要約文字列
    var summary: String {
        return "\(modelName): \(String(format: "%.2f", inferenceTime * 1000))ms, \(String(format: "%.1f", memoryUsage))MB, \(String(format: "%.1f", cpuUsage))%"
    }
}

/// @ai[2024-12-19 15:30] ベンチマーク設定定義
/// 性能測定の実行設定を管理
struct BenchmarkConfiguration {
    let iterations: Int
    let warmupIterations: Int
    let timeout: TimeInterval
    let enableMemoryProfiling: Bool
    let enableCPUProfiling: Bool
    let enableBatteryProfiling: Bool
    
    static let `default` = BenchmarkConfiguration(
        iterations: 10,
        warmupIterations: 3,
        timeout: 30.0,
        enableMemoryProfiling: true,
        enableCPUProfiling: true,
        enableBatteryProfiling: true
    )
}

/// @ai[2024-12-19 15:30] 性能統計定義
/// 複数の測定結果から計算される統計情報
struct PerformanceStatistics {
    let mean: Double
    let median: Double
    let standardDeviation: Double
    let min: Double
    let max: Double
    let percentile95: Double
    let percentile99: Double
    
    init(from values: [Double]) {
        let sortedValues = values.sorted()
        let count = Double(values.count)
        
        let mean = values.reduce(0, +) / count
        self.mean = mean
        
        self.median = sortedValues.count % 2 == 0 ?
            (sortedValues[sortedValues.count / 2 - 1] + sortedValues[sortedValues.count / 2]) / 2 :
            sortedValues[sortedValues.count / 2]
        
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / count
        self.standardDeviation = sqrt(variance)
        
        self.min = sortedValues.first ?? 0
        self.max = sortedValues.last ?? 0
        
        self.percentile95 = sortedValues[Int(count * 0.95)]
        self.percentile99 = sortedValues[Int(count * 0.99)]
    }
}

/// @ai[2024-12-19 15:30] アカウント抽出結果の構造体
/// アカウント情報抽出の結果を格納
@available(iOS 26.0, macOS 26.0, *)
public struct AccountExtractionResult: Identifiable {
    public let id = UUID()
    public let success: Bool
    public let accountInfo: AccountInfo?
    public let metrics: ExtractionMetrics?
    public let error: Error?
    public let timestamp: Date
    
    public init(success: Bool, accountInfo: AccountInfo? = nil, metrics: ExtractionMetrics? = nil, error: Error? = nil) {
        self.success = success
        self.accountInfo = accountInfo
        self.metrics = metrics
        self.error = error
        self.timestamp = Date()
    }
}
