import Foundation
import os.log

/// @ai[2025-01-18 08:00] ログ出力の統一ラッパークラス
/// 目的: loggerとprintを統一したインターフェイスで提供し、デバッグ時の可視性を向上
/// 背景: macOSのlogger.debug()はデフォルトで表示されず、デバッグが困難
/// 意図: すべてのログ出力をprint()で統一し、デバッグ時の可視性を確保
public class LogWrapper {
    private let logger: Logger
    private let subsystem: String
    private let category: String
    
    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    /// @ai[2025-01-18 08:00] デバッグレベルのログ出力
    /// 目的: デバッグ情報を統一された形式で出力
    /// 背景: logger.debug()は表示されないため、print()を使用
    /// 意図: デバッグ時の可視性を確保し、開発効率を向上
    public func debug(_ message: String) {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        print("🔍 [\(timestamp)] [\(category)] \(message)")
        logger.debug("\(message)")
    }
    
    /// @ai[2025-01-18 08:00] 情報レベルのログ出力
    /// 目的: 一般的な情報を統一された形式で出力
    /// 背景: 処理の流れや重要な情報を記録
    /// 意図: 実行フローの可視化と問題の特定を容易にする
    public func info(_ message: String) {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        print("ℹ️ [\(timestamp)] [\(category)] \(message)")
        logger.info("\(message)")
    }
    
    /// @ai[2025-01-18 08:00] 警告レベルのログ出力
    /// 目的: 警告情報を統一された形式で出力
    /// 背景: 処理は継続するが注意が必要な状況を記録
    /// 意図: 潜在的な問題を早期に発見し、対処する
    public func warning(_ message: String) {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        print("⚠️ [\(timestamp)] [\(category)] \(message)")
        logger.warning("\(message)")
    }
    
    /// @ai[2025-01-18 08:00] エラーレベルのログ出力
    /// 目的: エラー情報を統一された形式で出力
    /// 背景: 処理が失敗した場合の詳細情報を記録
    /// 意図: エラーの原因特定と修正を迅速に行う
    public func error(_ message: String) {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        print("❌ [\(timestamp)] [\(category)] \(message)")
        logger.error("\(message)")
    }
    
    /// @ai[2025-01-18 08:00] 成功レベルのログ出力
    /// 目的: 成功情報を統一された形式で出力
    /// 背景: 処理が正常に完了した場合の確認情報を記録
    /// 意図: 処理の成功を明確に示し、デバッグを支援
    public func success(_ message: String) {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        print("✅ [\(timestamp)] [\(category)] \(message)")
        logger.info("\(message)")
    }
}

/// @ai[2025-01-18 08:00] ログ用の日時フォーマッター
/// 目的: ログ出力時のタイムスタンプを統一された形式で提供
/// 背景: デバッグ時の時系列把握を容易にする
/// 意図: ログの可読性と時系列の追跡を向上
extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
