import Foundation

/// @ai[2025-01-19 01:00] アカウント情報分析関連の構造体
/// 目的: AccountInfoの分析処理を分離してコードの可読性を向上
/// 背景: AccountInfo.swiftの肥大化を防ぐため、分析関連の処理を分離
/// 意図: 保守性の向上とコードの整理

/// フィールド分析結果
@available(iOS 26.0, macOS 26.0, *)
public struct FieldAnalysis: Codable, Sendable {
    public let fieldName: String
    public let extractedValue: String?
    public let expectedValue: String
    public let status: String
    public let requiresVerification: Bool
    
    public init(fieldName: String, extractedValue: String?, expectedValue: String, status: String, requiresVerification: Bool) {
        self.fieldName = fieldName
        self.extractedValue = extractedValue
        self.expectedValue = expectedValue
        self.status = status
        self.requiresVerification = requiresVerification
    }
}

/// ノート内容分析結果
@available(iOS 26.0, macOS 26.0, *)
public struct NoteContentAnalysis: Codable, Sendable {
    public let totalFields: Int
    public let extractedFields: Int
    public let missingFields: Int
    public let accuracy: Double
    public let fieldAnalyses: [FieldAnalysis]
    
    public init(from results: [AccountExtractionResult]) {
        self.totalFields = 0
        self.extractedFields = 0
        self.missingFields = 0
        self.accuracy = 0.0
        self.fieldAnalyses = []
    }
}

/// AI応答分析結果
@available(iOS 26.0, macOS 26.0, *)
public struct AIResponseAnalysis: Codable, Sendable {
    public let totalResponses: Int
    public let successfulExtractions: Int
    public let failedExtractions: Int
    public let averageConfidence: Double
    public let commonErrors: [String: Int]
    
    public init(from results: [AccountExtractionResult]) {
        self.totalResponses = results.count
        self.successfulExtractions = results.filter { $0.success }.count
        self.failedExtractions = results.filter { !$0.success }.count
        self.averageConfidence = results.compactMap { $0.accountInfo?.confidence }.reduce(0, +) / Double(results.count)
        self.commonErrors = [:]
    }
    
    public init(results: [AccountExtractionResult], testText: String) {
        self.totalResponses = results.count
        self.successfulExtractions = results.filter { $0.success }.count
        self.failedExtractions = results.filter { !$0.success }.count
        self.averageConfidence = results.compactMap { $0.accountInfo?.confidence }.reduce(0, +) / Double(results.count)
        self.commonErrors = [:]
    }
}

/// テストケース名を解析してパターンとレベルを取得
public func parseTestCaseName(_ name: String) -> (pattern: String, level: Int) {
    let components = name.split(separator: " ")
    
    if components.count >= 2 {
        let pattern = String(components[0])
        let levelString = String(components[1])
        
        if levelString.hasPrefix("level") {
            let levelNumber = String(levelString.dropFirst(5)) // "level"を除去
            if let level = Int(levelNumber) {
                return (pattern, level)
            }
        }
    }
    
    // デフォルト値
    return ("Chat", 1)
}

/// 期待されるフィールドを取得
public func getExpectedFields(for pattern: String, level: Int) -> [String] {
    // 有効なパターンとレベルの確認
    let validPatterns = ["Chat", "Contract", "CreditCard", "VoiceRecognition", "PasswordManager"]
    guard validPatterns.contains(pattern) && (1...3).contains(level) else {
        return []
    }
    
    // パターンとレベルに応じた期待フィールドを定義
    switch pattern {
    case "Chat":
        switch level {
        case 1:
            return ["title", "userID", "password", "note"]
        case 2:
            return ["title", "userID", "password", "url", "note", "port"]
        case 3:
            return ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
        default:
            return []
        }
    case "Contract":
        switch level {
        case 1:
            return ["title", "userID", "password", "url", "note"]
        case 2:
            return ["title", "userID", "password", "url", "note", "host", "port"]
        case 3:
            return ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
        default:
            return []
        }
    case "CreditCard":
        switch level {
        case 1:
            return ["title", "userID", "password", "url", "note"]
        case 2:
            return ["title", "userID", "password", "url", "note", "host", "port"]
        case 3:
            return ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
        default:
            return []
        }
    case "VoiceRecognition":
        switch level {
        case 1:
            return ["title", "userID", "password", "url", "note"]
        case 2:
            return ["title", "userID", "password", "url", "note", "host", "port"]
        case 3:
            return ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
        default:
            return []
        }
    case "PasswordManager":
        switch level {
        case 1:
            return ["title", "userID", "password", "url", "note"]
        case 2:
            return ["title", "userID", "password", "url", "note", "host", "port"]
        case 3:
            return ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
        default:
            return []
        }
    default:
        return []
    }
}

/// フィールドの値を取得
@available(iOS 26.0, macOS 26.0, *)
public func getFieldValue(_ accountInfo: AccountInfo, fieldName: String) -> String? {
    switch fieldName {
    case "title": return accountInfo.title
    case "userID": return accountInfo.userID
    case "password": return accountInfo.password
    case "url": return accountInfo.url
    case "note": return accountInfo.note
    case "host": return accountInfo.host
    case "port": return accountInfo.port?.description
    case "authKey": return accountInfo.authKey
    default: return nil
    }
}

/// 期待値を取得
public func getExpectedValue(for fieldName: String, testCaseName: String) -> String {
    let (pattern, level) = parseTestCaseName(testCaseName)
    
    // 期待値の定義（実際のテストケースに応じて調整が必要）
    let expectedValues: [String: [String: [String: String]]] = [
        "Chat": [
            "level1": [
                "title": "Example Server",
                "userID": "admin",
                "password": "securepassword123",
                "url": "https://www.example.com/login",
                "note": "Firewall allows port 8080"
            ],
            "level2": [
                "title": "Example Server",
                "userID": "admin",
                "password": "securepassword123",
                "url": "https://www.example.com/login",
                "note": "Firewall allows port 8080",
                "host": "22.22.22.22",
                "port": "22010"
            ],
            "level3": [
                "title": "Example Server",
                "userID": "admin",
                "password": "securepassword123",
                "url": "https://www.example.com/login",
                "note": "Firewall allows port 8080",
                "host": "22.22.22.22",
                "port": "22010",
                "authKey": "-----BEGIN OPENSSH PRIVATE KEY-----"
            ]
        ]
    ]
    
    return expectedValues[pattern]?[level.description]?[fieldName] ?? "Unknown"
}

/// フィールドの状態を判定
public func determineFieldStatus(fieldName: String, extractedValue: String?, expectedValue: String) -> String {
    guard let extracted = extractedValue else {
        return "Missing"
    }
    
    if extracted.isEmpty {
        return "Empty"
    }
    
    if extracted == expectedValue {
        return "Exact Match"
    }
    
    if extracted.lowercased().contains(expectedValue.lowercased()) || expectedValue.lowercased().contains(extracted.lowercased()) {
        return "Partial Match"
    }
    
    return "Mismatch"
}

/// AI検証が必要かどうかを判定
public func requiresAIVerification(fieldName: String, extractedValue: String) -> Bool {
    switch fieldName {
    case "title", "userID", "url", "host":
        // これらのフィールドは明確な正解がある
        return false
    case "password", "authKey":
        // セキュリティ関連のフィールドは検証が必要
        return true
    case "note":
        // ノートは内容が複雑で検証が必要
        return true
    case "port":
        // ポート番号は数値の範囲チェックが必要
        return true
    default:
        return false
    }
}
