import Foundation
import FoundationModels
import os.log

/// @ai[2024-12-19 16:30] AIサポート検出ユーティリティ
/// デバイス要件、OSバージョン、AI機能の利用可能性を詳細にチェック
@available(iOS 26.0, macOS 26.0, *)
public class AISupportChecker: ObservableObject {
    private let logger = Logger(subsystem: "com.aitest.aisupport", category: "AISupportChecker")
    
    /// AIサポート状態
    @Published public var supportStatus: AISupportStatus = .checking
    
    /// デバイス情報
    @Published public var deviceInfo: DeviceInfo?
    
    /// 利用可能なAIモデル
    @Published public var availableModels: [AIModelInfo] = []
    
    /// イニシャライザ
    // @ai[2024-12-19 17:00] ビルドエラー修正: concurrencyエラーを修正
    // エラー: sending 'self' risks causing data races
    public init() {
        // 初期化時はチェック中状態で開始
        self.supportStatus = .checking
        self.deviceInfo = DeviceInfo(model: "Unknown", systemVersion: "Unknown", architecture: "Unknown", isSimulator: false)
        self.availableModels = []
    }
    
    /// AIサポートの包括的チェック（システムAPI使用）
    /// @ai[2024-12-19 16:30] Apple公式APIを使用したAI機能の利用可能性検証
    /// 目的: システムAPIの結果のみに依存してAI利用可能性を判定
    /// 背景: Apple公式ドキュメントに従った正確な実装
    /// 意図: 自己判断を避け、公式APIの結果のみに依存
    @MainActor
    public func checkAISupport() async {
        logger.info("🔍 AIサポート検出を開始（システムAPI使用）")
        
        // デバイス情報の取得（表示用のみ）
        // @ai[2024-12-19 17:00] ビルドエラー修正: concurrencyエラーを修正
        // エラー: sending 'self' risks causing data races
        let device = await getDeviceInfo()
        self.deviceInfo = device
        
        // Apple Intelligence利用可能性をシステムAPIでチェック
        let availabilityResult = await checkAppleIntelligenceAvailability()
        
        switch availabilityResult {
        case .available:
            // 利用可能なモデルの取得
            let models = await getAvailableModels()
            self.availableModels = models
            self.supportStatus = .supported
            logger.info("✅ AIサポート検出完了 - ステータス: supported")
            
        case .unavailable(let reason):
            let status = mapAvailabilityToStatus(reason)
            self.supportStatus = status
            logger.warning("⚠️ AI利用不可 - 理由: \(String(describing: reason))")
        }
    }
    
    /// デバイス情報を取得
    @MainActor
    private func getDeviceInfo() async -> DeviceInfo {
        let device = DeviceInfo(
            model: getDeviceModel(),
            systemVersion: getSystemVersion(),
            architecture: getArchitecture(),
            isSimulator: isRunningOnSimulator()
        )
        
        logger.info("📱 デバイス情報: \(device.model) - \(device.systemVersion) - \(device.architecture)")
        return device
    }
    
    /// 利用可能性の理由をステータスにマッピング
    private func mapAvailabilityToStatus(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> AISupportStatus {
        switch reason {
        case .appleIntelligenceNotEnabled:
            return .appleIntelligenceNotEnabled
        case .deviceNotEligible:
            return .deviceNotEligible
        case .modelNotReady:
            return .modelNotReady
        @unknown default:
            return .error(NSError(domain: "AISupportChecker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown availability reason: \(reason)"]))
        }
    }
    
    /// Apple Intelligence利用可能性をチェック（システムAPI使用）
    /// @ai[2024-12-19 16:30] Apple公式APIを使用した正確な利用可能性チェック
    /// 目的: システムAPIの結果のみに依存して判定
    /// 背景: Apple公式ドキュメントに従った正確な実装
    /// 意図: 公式APIの結果をそのまま返すことで信頼性を確保
    @MainActor
    private func checkAppleIntelligenceAvailability() async -> SystemLanguageModel.Availability {
        
        let systemModel = SystemLanguageModel.default
        let availability = systemModel.availability
        
        logger.info("🔍 システムAPI利用可能性チェック結果: \(String(describing: availability))")
        
        switch availability {
        case .available:
            logger.info("✅ Apple Intelligence利用可能（システムAPI確認済み）")
            
        case .unavailable(.appleIntelligenceNotEnabled):
            logger.warning("⚠️ Apple Intelligenceが無効です（システムAPI確認済み）")
            
        case .unavailable(.deviceNotEligible):
            logger.warning("⚠️ このデバイスではAIモデルを利用できません（システムAPI確認済み）")
            
        case .unavailable(.modelNotReady):
            logger.warning("⚠️ モデルをダウンロード中です（システムAPI確認済み）")
            
        case .unavailable(let reason):
            logger.warning("⚠️ Apple Intelligence利用不可（システムAPI確認済み）: \(String(describing: reason))")
        }
        
        return availability
    }
    
    /// 利用可能なAIモデルを取得
    @MainActor
    private func getAvailableModels() async -> [AIModelInfo] {
        var models: [AIModelInfo] = []
        
        // ローカルLLM（Apple Intelligence Foundation Model）
        let systemModel = SystemLanguageModel.default
        if systemModel.isAvailable {
            models.append(AIModelInfo(
                id: "apple-intelligence",
                name: "Apple Intelligence Foundation Model",
                type: .localLLM,
                isAvailable: true,
                description: "Apple Intelligence Foundation Model（ローカル実行）"
            ))
        }
        
        // 将来的にGPTなどの外部モデルも追加可能
        // models.append(AIModelInfo(...))
        
        logger.info("🤖 利用可能なAIモデル: \(models.count)個")
        return models
    }
    
    // MARK: - Helper Methods
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine.0) {
            String(cString: $0)
        }
        return modelCode
    }
    
    private func getSystemVersion() -> String {
        return ProcessInfo.processInfo.operatingSystemVersionString
    }
    
    private func getArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
    
    private func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

/// AIサポート状態
@available(iOS 26.0, macOS 26.0, *)
public enum AISupportStatus {
    case checking
    case supported
    case unsupportedOS
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case error(Error)
    
    public var displayName: String {
        switch self {
        case .checking:
            return "チェック中..."
        case .supported:
            return "AI機能利用可能"
        case .unsupportedOS:
            return "OSバージョンが要件を満たしていません"
        case .deviceNotEligible:
            return "このデバイスではAI機能を利用できません"
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligenceが無効です"
        case .modelNotReady:
            return "AIモデルをダウンロード中です"
        case .error(let error):
            return "エラー: \(error.localizedDescription)"
        }
    }
    
    public var isSupported: Bool {
        if case .supported = self {
            return true
        }
        return false
    }
}

/// デバイス情報
public struct DeviceInfo: Codable {
    public let model: String
    public let systemVersion: String
    public let architecture: String
    public let isSimulator: Bool
    
    public init(model: String, systemVersion: String, architecture: String, isSimulator: Bool) {
        self.model = model
        self.systemVersion = systemVersion
        self.architecture = architecture
        self.isSimulator = isSimulator
    }
}

/// AIモデル情報
public struct AIModelInfo: Codable, Identifiable {
    public let id: String
    public let name: String
    public let type: AIModelType
    public let isAvailable: Bool
    public let description: String
    
    public init(id: String, name: String, type: AIModelType, isAvailable: Bool, description: String) {
        self.id = id
        self.name = name
        self.type = type
        self.isAvailable = isAvailable
        self.description = description
    }
}

/// AIモデルタイプ
public enum AIModelType: String, CaseIterable, Codable {
    case localLLM = "Local LLM"
    case gpt = "GPT"
    case claude = "Claude"
    case gemini = "Gemini"
    
    public var displayName: String {
        switch self {
        case .localLLM:
            return "ローカルLLM"
        case .gpt:
            return "GPT"
        case .claude:
            return "Claude"
        case .gemini:
            return "Gemini"
        }
    }
}
