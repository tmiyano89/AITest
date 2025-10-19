import Foundation

/// @ai[2024-12-19 20:00] 処理時間計測ユーティリティ
/// 目的: 各関数の処理時間を計測してボトルネックを特定
/// 背景: 並列処理の効率性向上のため、詳細な性能分析が必要
/// 意図: リアルタイムでの処理時間監視とログ出力
public class PerformanceTimer {
    private var startTime: Date?
    private let label: String
    
    public init(_ label: String) {
        self.label = label
    }
    
    public func start() {
        startTime = Date()
        print("⏱️  [\(label)] 開始")
    }
    
    public func end() {
        guard let startTime = startTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        print("⏱️  [\(label)] 完了: \(String(format: "%.3f", duration))秒")
    }
    
    public func checkpoint(_ message: String) {
        guard let startTime = startTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        print("⏱️  [\(label)] \(message): \(String(format: "%.3f", duration))秒")
    }
}
