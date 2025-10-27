import Foundation
import FoundationModels

/// @ai[2024-12-19 20:00] アカウント情報を表す構造体
/// 公式ドキュメントに基づくGuided Generation最適化設計
/// @Generableマクロと@Guideマクロでモデル出力を制御
/// 
/// 注意：現在のマクロの仕様により、@Generableを指定した構造体をpublicにするとビルドエラーが発生します
/// そのため、SecureExtractAPIのメソッドもinternalとして定義し、外部からは別の方法でアクセスします
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "サービスのアカウントに関する情報")
public struct AccountInfo: Codable, Identifiable, Sendable {
    public let id = UUID()
    
    /// サービス名、アプリ名、サイト名
    @Guide(description: "サービスやシステムの名前または提供者名(例: 'Example Server', 'GitHub')[必須]")
    public var title: String?
    
    /// メールアドレス、ユーザー名、ログインID
    @Guide(description: "ログイン用のユーザーIDやメールアドレス(例: 'admin', 'johndoe@example.com')")
    public var userID: String?
    
    /// パスワード文字列
    @Guide(description: "ログイン用のパスワード文字列(例: 'securepassword123')")
    public var password: String?
    
    /// ログインページURL、サービスURL
    @Guide(description: "ログインページのURL(例: 'https://www.example.com/login')")
    public var url: String?

    /// アカウントやカードの識別番号
    @Guide(description: "契約番号やカード番号、アカウントIDなどの識別番号(例: 4090-3284-3284-3283)")
    public var number: String?

    /// 備考、メモ、追加情報
    @Guide(description: "サービスに関する補足情報(例: 'Firewall allows port 8080\nufw allow 8080/tcp\n契約期限は2025年12月31日まで')[必須]")
    public var note: String?
    
    /// ホスト名またはIPアドレス（SSH/RDP接続用）
    @Guide(description: "接続先のホスト名またはIPアドレス(例: '22.22.22.22')")
    public var host: String?
    
    /// ポート番号（SSH/RDP接続用）
    @Guide(description: "接続ポート番号(例: 22010)", .range(1...65535))
    public var port: Int?
    
    /// 認証キー（SSH秘密鍵、証明書など）
    @Guide(description: "SSH秘密鍵や認証キーの完全な文字列(例: '-----BEGIN OPENSSH PRIVATE KEY-----から始まり、-----END OPENSSH PRIVATE KEY-----で終わる複数行の文字列')")
    public var authKey: String?
    
    /// 抽出された情報の信頼度（0.0-1.0）
    @Guide(description: "抽出精度の自己評価", .range(0.0...1.0))
    public var confidence: Double?
    
    /// イニシャライザ
    public init(
        title: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        url: String? = nil,
        note: String? = nil,
        host: String? = nil,
        port: Int? = nil,
        authKey: String? = nil,
        confidence: Double? = nil
    ) {
        self.title = title
        self.userID = userID
        self.password = password
        self.url = url
        self.note = note
        self.host = host
        self.port = port
        self.authKey = authKey
        self.confidence = confidence
    }
    
    /// CodingKeysを明示的に定義（idは除外）
    enum CodingKeys: String, CodingKey {
        case title
        case userID
        case password
        case url
        case note
        case host
        case port
        case authKey
        case confidence
    }
    
    /// バリデーションメソッド（警告フラグのみ、処理は中断しない）
    public func validate() -> ValidationResult {
        var warnings: [ValidationWarning] = []
        
        // 最低限一つのフィールドが必要
        if title == nil && userID == nil && password == nil && url == nil && 
           note == nil && host == nil && authKey == nil {
            warnings.append(.noDataExtracted)
        }
        
        // URLフィールドがある場合の形式チェック
        if let urlString = url, !urlString.isEmpty {
            if URL(string: urlString) == nil {
                warnings.append(.invalidURL(urlString))
            }
        }
        
        // メールアドレス形式チェック（userIDがメールアドレスの場合）
        if let userID = userID, userID.contains("@") {
            let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: userID) {
                warnings.append(.invalidEmail(userID))
            }
        }
        
        // ホスト名またはIPアドレスの形式チェック
        if let host = host, !host.isEmpty {
            if !isValidHostnameOrIP(host) {
                warnings.append(.invalidHost(host))
            }
        }
        
        // ポート番号の範囲チェック
        if let port = port {
            if !(1...65535).contains(port) {
                warnings.append(.invalidPort(port))
            }
        }
        
        // SSH秘密鍵形式の基本チェック
        if let authKey = authKey, !authKey.isEmpty {
            if !isValidSSHKey(authKey) {
                warnings.append(.invalidAuthKey)
            }
        }
        
        // 信頼度の範囲チェック
        if let confidence = confidence {
            if !(0.0...1.0).contains(confidence) {
                warnings.append(.invalidConfidence(confidence))
            }
        }
        
        return ValidationResult(warnings: warnings)
    }
    
    /// ホスト名またはIPアドレスの妥当性チェック
    private func isValidHostnameOrIP(_ host: String) -> Bool {
        // IPアドレスパターン
        let ipv4Pattern = #"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#
        let ipv6Pattern = #"^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"#
        
        // ホスト名パターン（簡易版）
        let hostnamePattern = #"^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$"#
        
        let ipv4Predicate = NSPredicate(format: "SELF MATCHES %@", ipv4Pattern)
        let ipv6Predicate = NSPredicate(format: "SELF MATCHES %@", ipv6Pattern)
        let hostnamePredicate = NSPredicate(format: "SELF MATCHES %@", hostnamePattern)
        
        return ipv4Predicate.evaluate(with: host) || 
               ipv6Predicate.evaluate(with: host) || 
               hostnamePredicate.evaluate(with: host)
    }
    
    /// SSH秘密鍵の基本形式チェック
    private func isValidSSHKey(_ key: String) -> Bool {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 一般的なSSH秘密鍵のヘッダーパターン
        let keyPatterns = [
            "-----BEGIN OPENSSH PRIVATE KEY-----",
            "-----BEGIN RSA PRIVATE KEY-----",
            "-----BEGIN DSA PRIVATE KEY-----",
            "-----BEGIN EC PRIVATE KEY-----",
            "-----BEGIN PRIVATE KEY-----",
            "-----BEGIN ENCRYPTED PRIVATE KEY-----"
        ]
        
        return keyPatterns.contains { trimmedKey.contains($0) }
    }
    
    /// データが有効かどうかを判定
    public var isValid: Bool {
        let validationResult = validate()
        return validationResult.isValid
    }
    
    /// 抽出されたフィールド数をカウント
    public var extractedFieldsCount: Int {
        var count = 0
        if title != nil { count += 1 }
        if userID != nil { count += 1 }
        if password != nil { count += 1 }
        if url != nil { count += 1 }
        if note != nil { count += 1 }
        if host != nil { count += 1 }
        if port != nil { count += 1 }
        if authKey != nil { count += 1 }
        return count
    }
    
    /// アカウントタイプを判定
    public var accountType: AccountType {
        if host != nil || port != nil || authKey != nil {
            if port == 22 || authKey != nil {
                return .ssh
            } else if port == 3389 {
                return .rdp
            } else {
                return .remoteAccess
            }
        } else if url != nil {
            return .web
        } else {
            return .general
        }
    }
}

// @ai[2024-12-19 20:00] @Generableマクロにより自動生成されるため、手動実装は不要

/// アカウントタイプ
public enum AccountType: String, CaseIterable {
    case web = "Web"
    case ssh = "SSH"
    case rdp = "RDP"
    case remoteAccess = "リモートアクセス"
    case general = "一般"
    
    public var icon: String {
        switch self {
        case .web: return "globe"
        case .ssh: return "terminal"
        case .rdp: return "desktopcomputer"
        case .remoteAccess: return "network"
        case .general: return "key.fill"
        }
    }
}

/// バリデーション結果
@available(iOS 26.0, macOS 26.0, *)
public struct ValidationResult: Codable, Sendable {
    public let warnings: [ValidationWarning]
    public let isValid: Bool
    
    public init(warnings: [ValidationWarning]) {
        self.warnings = warnings
        self.isValid = warnings.isEmpty
    }
}

/// バリデーション警告定義
@available(iOS 26.0, macOS 26.0, *)
public enum ValidationWarning: LocalizedError, Codable, Sendable {
    case noDataExtracted
    case invalidURL(String)
    case invalidEmail(String)
    case invalidHost(String)
    case invalidPort(Int)
    case invalidAuthKey
    case invalidConfidence(Double)
    
    public var errorDescription: String? {
        switch self {
        case .noDataExtracted:
            return "抽出されたデータがありません"
        case .invalidURL(let url):
            return "無効なURL形式です: \(url)"
        case .invalidEmail(let email):
            return "無効なメールアドレス形式です: \(email)"
        case .invalidHost(let host):
            return "無効なホスト名またはIPアドレスです: \(host)"
        case .invalidPort(let port):
            return "無効なポート番号です: \(port)"
        case .invalidAuthKey:
            return "無効な認証キー形式です"
        case .invalidConfidence(let confidence):
            return "信頼度は0.0-1.0の範囲である必要があります: \(confidence)"
        }
    }
}

/// 抽出精度メトリクス
@available(iOS 26.0, macOS 26.0, *)
public struct ExtractionAccuracyMetrics: Codable, Sendable {
    /// 正解データ
    public let expectedData: AccountInfo
    /// 抽出結果
    public let extractedData: AccountInfo
    /// フィールド別精度（0.0-1.0）
    public let fieldAccuracy: [String: Double]
    /// 全体精度（0.0-1.0）
    public let overallAccuracy: Double
    /// 誤抽出の詳細
    public let extractionErrors: [ExtractionAccuracyError]
    
    public init(expectedData: AccountInfo, extractedData: AccountInfo) {
        self.expectedData = expectedData
        self.extractedData = extractedData
        
        // フィールド別精度を計算
        var fieldAccuracy: [String: Double] = [:]
        var extractionErrors: [ExtractionAccuracyError] = []
        
        // 各フィールドの精度を計算
        fieldAccuracy["title"] = Self.calculateFieldAccuracy(expected: expectedData.title, extracted: extractedData.title, fieldName: "title", errors: &extractionErrors)
        fieldAccuracy["userID"] = Self.calculateFieldAccuracy(expected: expectedData.userID, extracted: extractedData.userID, fieldName: "userID", errors: &extractionErrors)
        fieldAccuracy["password"] = Self.calculateFieldAccuracy(expected: expectedData.password, extracted: extractedData.password, fieldName: "password", errors: &extractionErrors)
        fieldAccuracy["url"] = Self.calculateFieldAccuracy(expected: expectedData.url, extracted: extractedData.url, fieldName: "url", errors: &extractionErrors)
        fieldAccuracy["note"] = Self.calculateFieldAccuracy(expected: expectedData.note, extracted: extractedData.note, fieldName: "note", errors: &extractionErrors)
        fieldAccuracy["host"] = Self.calculateFieldAccuracy(expected: expectedData.host, extracted: extractedData.host, fieldName: "host", errors: &extractionErrors)
        fieldAccuracy["port"] = Self.calculateFieldAccuracy(expected: expectedData.port, extracted: extractedData.port, fieldName: "port", errors: &extractionErrors)
        fieldAccuracy["authKey"] = Self.calculateFieldAccuracy(expected: expectedData.authKey, extracted: extractedData.authKey, fieldName: "authKey", errors: &extractionErrors)
        
        self.fieldAccuracy = fieldAccuracy
        self.extractionErrors = extractionErrors
        
        // 全体精度を計算
        let accuracies = fieldAccuracy.values
        self.overallAccuracy = accuracies.isEmpty ? 0.0 : accuracies.reduce(0, +) / Double(accuracies.count)
    }
    
    private static func calculateFieldAccuracy<T: Equatable>(expected: T?, extracted: T?, fieldName: String, errors: inout [ExtractionAccuracyError]) -> Double {
        switch (expected, extracted) {
        case (nil, nil):
            return 1.0 // 両方ともnil（正解）
        case (nil, _):
            errors.append(.falsePositive(field: fieldName, extracted: "\(extracted!)"))
            return 0.0 // 誤って抽出
        case (_, nil):
            errors.append(.falseNegative(field: fieldName, expected: "\(expected!)"))
            return 0.0 // 抽出漏れ
        case (let expectedValue?, let extractedValue?):
            if expectedValue == extractedValue {
                return 1.0 // 完全一致
            } else {
                errors.append(.incorrectValue(field: fieldName, expected: "\(expectedValue)", extracted: "\(extractedValue)"))
                return 0.0 // 値が間違っている
            }
        }
    }
}

/// 項目レベルでの抽出成功度分析
@available(iOS 26.0, macOS 26.0, *)
public struct FieldLevelAnalysis: Codable, Sendable {
    /// 各フィールドの成功率（0.0-1.0）
    public let fieldSuccessRates: [String: Double]
    /// 各フィールドの抽出回数
    public let fieldExtractionCounts: [String: Int]
    /// 各フィールドのエラー回数
    public let fieldErrorCounts: [String: Int]
    /// 各フィールドの文字レベル精度
    public let fieldCharacterAccuracy: [String: Double]
    /// 各フィールドの期待値（テストケースから推定）
    public let fieldExpectedValues: [String: String?]
    /// noteフィールドの内容分析
    public let noteContentAnalysis: NoteContentAnalysis
    /// AI回答分析
    public let aiResponseAnalysis: AIResponseAnalysis
    /// 総テスト数
    public let totalTests: Int
    
    public init(results: [AccountExtractionResult], testText: String) {
        let fields = ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
        var fieldSuccessRates: [String: Double] = [:]
        var fieldExtractionCounts: [String: Int] = [:]
        var fieldErrorCounts: [String: Int] = [:]
        var fieldCharacterAccuracy: [String: Double] = [:]
        var fieldExpectedValues: [String: String?] = [:]
        
        let totalTests = results.count
        
        // テストテキストから期待値を推定
        let expectedValues = Self.extractExpectedValues(from: testText)
        
        for field in fields {
            var successCount = 0
            var extractionCount = 0
            var errorCount = 0
            var totalCharacterAccuracy = 0.0
            var accuracyCount = 0
            
            let expectedValue = expectedValues[field]
            fieldExpectedValues[field] = expectedValue
            
            for result in results {
                guard let accountInfo = result.accountInfo else {
                    errorCount += 1
                    continue
                }
                
                let hasField = accountInfo.hasField(field)
                if hasField {
                    extractionCount += 1
                    
                    // 文字レベル精度を計算
                    if let extractedValue = accountInfo.getValue(for: field),
                       let expected = expectedValue {
                        let accuracy = Self.calculateCharacterAccuracy(expected: expected!, extracted: extractedValue)
                        totalCharacterAccuracy += accuracy
                        accuracyCount += 1
                    }
                    
                    // バリデーションエラーがない場合のみ成功とみなす
                    if result.success {
                        successCount += 1
                    } else {
                        errorCount += 1
                    }
                } else {
                    errorCount += 1
                }
            }
            
            fieldSuccessRates[field] = totalTests > 0 ? Double(successCount) / Double(totalTests) : 0.0
            fieldExtractionCounts[field] = extractionCount
            fieldErrorCounts[field] = errorCount
            fieldCharacterAccuracy[field] = accuracyCount > 0 ? totalCharacterAccuracy / Double(accuracyCount) : 0.0
        }
        
        self.fieldSuccessRates = fieldSuccessRates
        self.fieldExtractionCounts = fieldExtractionCounts
        self.fieldErrorCounts = fieldErrorCounts
        self.fieldCharacterAccuracy = fieldCharacterAccuracy
        self.fieldExpectedValues = fieldExpectedValues
        self.noteContentAnalysis = NoteContentAnalysis(from: results)
        self.aiResponseAnalysis = AIResponseAnalysis(from: results)
        self.totalTests = totalTests
    }
    
    /// テストテキストから期待値を推定
    private static func extractExpectedValues(from testText: String) -> [String: String?] {
        var expectedValues: [String: String?] = [:]
        
        // 基本的なパターンマッチングで期待値を抽出
        let patterns: [String: String] = [
            "userID": #"(?:user|id|username|login)[\s:：]*([a-zA-Z0-9@._-]+)"#,
            "password": #"(?:pass|password|pw)[\s:：]*([a-zA-Z0-9!@#$%^&*()_+-=]+)"#,
            "title": #"(?:service|app|site|title)[\s:：]*([a-zA-Z0-9\s]+)"#,
            "url": #"(https?://[a-zA-Z0-9.-]+[a-zA-Z0-9.-/]*)"#,
            "host": #"(?:host|server|ip)[\s:：]*([a-zA-Z0-9.-]+)"#,
            "port": #"(?:port)[\s:：]*(\d+)"#,
            "authKey": #"(-----BEGIN[^-]+-----[\s\S]*?-----END[^-]+-----)"#
        ]
        
        for (field, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(testText.startIndex..., in: testText)
                if let match = regex.firstMatch(in: testText, options: [], range: range) {
                    let matchRange = match.range(at: 1)
                    if let swiftRange = Range(matchRange, in: testText) {
                        expectedValues[field] = String(testText[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        
        return expectedValues
    }
    
    /// 文字レベル精度を計算
    private static func calculateCharacterAccuracy(expected: String, extracted: String) -> Double {
        let expectedClean = expected.lowercased().replacingOccurrences(of: " ", with: "")
        let extractedClean = extracted.lowercased().replacingOccurrences(of: " ", with: "")
        
        let maxLength = max(expectedClean.count, extractedClean.count)
        guard maxLength > 0 else { return 1.0 }
        
        let distance = levenshteinDistance(expectedClean, extractedClean)
        let accuracy = Double(maxLength - distance) / Double(maxLength)
        return max(0.0, accuracy)
    }
    
    /// レーベンシュタイン距離を計算
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            matrix[i][0] = i
        }
        
        for j in 0...n {
            matrix[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                let cost = a[i-1] == b[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[m][n]
    }
}

/// note内容アイテム
@available(iOS 26.0, macOS 26.0, *)
public struct NoteContentItem: Codable, Sendable {
    public let content: String
    public let count: Int
    
    public init(content: String, count: Int) {
        self.content = content
        self.count = count
    }
}


/// AccountInfoのフィールド存在チェック用拡張
@available(iOS 26.0, macOS 26.0, *)
extension AccountInfo {
    func hasField(_ field: String) -> Bool {
        switch field {
        case "title": return title != nil && !title!.isEmpty
        case "userID": return userID != nil && !userID!.isEmpty
        case "password": return password != nil && !password!.isEmpty
        case "url": return url != nil && !url!.isEmpty
        case "note": return note != nil && !note!.isEmpty
        case "host": return host != nil && !host!.isEmpty
        case "port": return port != nil
        case "authKey": return authKey != nil && !authKey!.isEmpty
        default: return false
        }
    }
    
    func getValue(for field: String) -> String? {
        switch field {
        case "title": return title
        case "userID": return userID
        case "password": return password
        case "url": return url
        case "note": return note
        case "host": return host
        case "port": return port?.description
        case "authKey": return authKey
        default: return nil
        }
    }
}

/// 抽出精度エラー定義
@available(iOS 26.0, macOS 26.0, *)
public enum ExtractionAccuracyError: Codable, Sendable {
    case falsePositive(field: String, extracted: String) // 誤って抽出
    case falseNegative(field: String, expected: String)  // 抽出漏れ
    case incorrectValue(field: String, expected: String, extracted: String) // 値が間違っている
    
    public var description: String {
        switch self {
        case .falsePositive(let field, let extracted):
            return "誤抽出: \(field)フィールドで不要な値「\(extracted)」を抽出"
        case .falseNegative(let field, let expected):
            return "抽出漏れ: \(field)フィールドで「\(expected)」を抽出できず"
        case .incorrectValue(let field, let expected, let extracted):
            return "値誤り: \(field)フィールドで期待値「\(expected)」に対して「\(extracted)」を抽出"
        }
    }
}

/// 抽出メトリクス
@available(iOS 26.0, macOS 26.0, *)
public struct ExtractionMetrics: Codable, Sendable {
    /// AI抽出処理時間（秒）
    public let extractionTime: TimeInterval
    
    /// 総処理時間（秒）
    public let totalTime: TimeInterval
    
    /// メモリ使用量（MB）
    public let memoryUsed: Double
    
    /// 入力テキスト長（文字数）
    public let textLength: Int
    
    /// 抽出されたフィールド数
    public let extractedFieldsCount: Int
    
    /// 信頼度スコア
    public let confidence: Double
    
    /// 抽出結果が有効かどうか
    public let isValid: Bool
    
    /// バリデーション結果
    public let validationResult: ValidationResult
    
    
    /// イニシャライザ
    public init(
        extractionTime: TimeInterval,
        totalTime: TimeInterval,
        memoryUsed: Double,
        textLength: Int,
        extractedFieldsCount: Int,
        confidence: Double,
        isValid: Bool,
        validationResult: ValidationResult
    ) {
        self.extractionTime = extractionTime
        self.totalTime = totalTime
        self.memoryUsed = memoryUsed
        self.textLength = textLength
        self.extractedFieldsCount = extractedFieldsCount
        self.confidence = confidence
        self.isValid = isValid
        self.validationResult = validationResult
    }
    
    /// 抽出効率（フィールド数/秒）
    public var extractionEfficiency: Double {
        guard extractionTime > 0 else { return 0 }
        return Double(extractedFieldsCount) / extractionTime
    }
    
    /// メモリ効率（フィールド数/MB）
    public var memoryEfficiency: Double {
        guard memoryUsed > 0 else { return 0 }
        return Double(extractedFieldsCount) / memoryUsed
    }
}

/// 2ステップ抽出メトリクス
/// @ai[2025-10-21 13:30] 2ステップ抽出のメトリクス定義
/// @ai[2025-10-22 20:00] confidence関連フィールドを削除（信頼性評価は不要）
/// 目的: 分割推定方式の各ステップの処理時間を記録
/// 背景: 推定1と推定2の個別のメトリクスを分析する必要
/// 意図: 2ステップ抽出の効果性を測定
@available(iOS 26.0, macOS 26.0, *)
public struct TwoStepsExtractionMetrics: Codable, Sendable {
    /// 推定1の処理時間（秒）
    public let step1Time: TimeInterval
    /// 推定2の処理時間（秒）
    public let step2Time: TimeInterval
    /// 総処理時間（秒）
    public let totalTime: TimeInterval
    /// 判定されたカテゴリ
    public let detectedCategory: String
    /// 抽出された情報タイプ数
    public let extractedInfoTypes: Int
    /// 抽出戦略の効果性
    public let strategyEffectiveness: Double
    /// 通常のメトリクス
    public let baseMetrics: ExtractionMetrics

    public init(
        step1Time: TimeInterval,
        step2Time: TimeInterval,
        totalTime: TimeInterval,
        detectedCategory: String,
        extractedInfoTypes: Int,
        strategyEffectiveness: Double,
        baseMetrics: ExtractionMetrics
    ) {
        self.step1Time = step1Time
        self.step2Time = step2Time
        self.totalTime = totalTime
        self.detectedCategory = detectedCategory
        self.extractedInfoTypes = extractedInfoTypes
        self.strategyEffectiveness = strategyEffectiveness
        self.baseMetrics = baseMetrics
    }
}

/// 抽出エラー定義
public enum ExtractionError: LocalizedError {
    case invalidInput
    case noAccountInfoFound
    case languageModelUnavailable
    case appleIntelligenceDisabled
    case deviceNotEligible
    case modelNotReady
    case aifmNotSupported
    case invalidImageData
    case promptTemplateNotFound(String)
    case mappingRuleNotFound(String)
    case invalidJSONFormat(aiResponse: String?)
    case invalidYAMLFormat
    case externalLLMError(response: String)
    case methodNotSupported(String)
    case invalidPattern(String)
    case testDataNotFound(String)
    
    /// AIレスポンスを取得
    public var aiResponse: String? {
        switch self {
        case .invalidJSONFormat(let response):
            return response
        case .externalLLMError(let response):
            return response
        default:
            return nil
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "無効な入力データです"
        case .noAccountInfoFound:
            return "アカウント情報が見つかりませんでした"
        case .languageModelUnavailable:
            return "言語モデルが利用できません"
        case .appleIntelligenceDisabled:
            return "Apple Intelligenceが無効です"
        case .deviceNotEligible:
            return "このデバイスではAIモデルを利用できません"
        case .modelNotReady:
            return "モデルをダウンロード中です"
        case .aifmNotSupported:
            return "FoundationModelsがサポートされていません"
        case .invalidImageData:
            return "無効な画像データです"
        case .promptTemplateNotFound(let filePath):
            return "プロンプトテンプレートファイルが見つかりません: \(filePath)"
        case .mappingRuleNotFound(let fileName):
            return "マッピングルールファイルが見つかりません: \(fileName)"
        case .invalidJSONFormat:
            return "無効なJSON形式です"
        case .invalidYAMLFormat:
            return "無効なYAML形式です"
        case .externalLLMError(_):
            return "外部LLMエラー: 無効なJSON形式です"
        case .methodNotSupported(let method):
            return "メソッドがサポートされていません: \(method)"
        case .invalidPattern(let pattern):
            return "無効なパターンです: \(pattern)"
        case .testDataNotFound(let path):
            return "テストデータが見つかりません: \(path)"
        }
    }
}

