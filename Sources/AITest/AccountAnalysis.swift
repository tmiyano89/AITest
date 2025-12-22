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

/// テストデータファイルの解析結果
/// @ai[2025-12-11 17:50] expectedCategoryフィールドを追加
/// @ai[2025-12-11 18:00] expectedCategoryを必須フィールドに変更
/// 目的: two-stepsモードでのカテゴリ判定精度を検証可能にする
/// 背景: テストケースファイルのヘッダで期待カテゴリを宣言し、検証ロジックを追加
/// 意図: カテゴリ判定の正しさを客観的に評価する。すべてのテストケースファイルで期待カテゴリの宣言を必須とする
@available(iOS 26.0, macOS 26.0, *)
public struct TestDataFile {
    public let expectedFields: [String]
    public let expectedCategory: (mainCategory: String, subCategory: String)
    public let cleanContent: String
}

/// テストデータファイルを解析して期待フィールドとクリーンなコンテンツを取得
/// - 先頭の複数のコメント行（//で始まる行）をサポート
/// - expectedFields:が必須、なければfatalError
/// - expectedCategory:が必須、なければfatalError
/// @ai[2025-12-11 18:00] expectedCategoryを必須に変更
/// 目的: すべてのテストケースファイルで期待カテゴリの宣言を必須とする
/// 背景: カテゴリ判定の精度を正確に評価するため
/// 意図: テストケースファイル作成時に期待カテゴリを忘れないようにする
@available(iOS 26.0, macOS 26.0, *)
public func parseTestDataFile(at path: String) throws -> TestDataFile {
    let content = try String(contentsOfFile: path, encoding: .utf8)
    let lines = content.split(separator: "\n", omittingEmptySubsequences: false)

    var expectedFields: [String] = []
    var expectedCategory: (mainCategory: String, subCategory: String)? = nil
    var firstNonCommentLineIndex = 0

    // 先頭のコメント行を全て解析
    for (index, line) in lines.enumerated() {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        if trimmedLine.hasPrefix("//") {
            // expectedFields:を探す
            if trimmedLine.hasPrefix("//expectedFields:") {
                let fieldsString = trimmedLine.replacingOccurrences(of: "//expectedFields:", with: "").trimmingCharacters(in: .whitespaces)
                expectedFields = fieldsString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            }
            // expectedCategory:を探す（形式: mainCategory,subCategory）
            if trimmedLine.hasPrefix("//expectedCategory:") {
                let categoryString = trimmedLine.replacingOccurrences(of: "//expectedCategory:", with: "").trimmingCharacters(in: .whitespaces)
                let categoryParts = categoryString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                if categoryParts.count == 2 {
                    expectedCategory = (mainCategory: categoryParts[0], subCategory: categoryParts[1])
                } else {
                    fatalError("❌ テストデータファイル '\(path)' の //expectedCategory: の形式が不正です。'//expectedCategory: mainCategory,subCategory' の形式で指定してください。例: '//expectedCategory: work,workServer'")
                }
            }
            // 他のコメント行は無視
        } else {
            // コメントでない行が見つかったら終了
            firstNonCommentLineIndex = index
            break
        }
    }

    // expectedFieldsが見つからない場合はfatalError
    guard !expectedFields.isEmpty else {
        fatalError("❌ テストデータファイル '\(path)' に //expectedFields: コメントが見つかりません。先頭に '//expectedFields: field1,field2,...' の形式で追加してください。")
    }

    // expectedCategoryが見つからない場合はfatalError
    guard let category = expectedCategory else {
        fatalError("❌ テストデータファイル '\(path)' に //expectedCategory: コメントが見つかりません。先頭に '//expectedCategory: mainCategory,subCategory' の形式で追加してください。例: '//expectedCategory: work,workServer'")
    }

    // クリーンなコンテンツ（コメント行を除く）
    let cleanLines = Array(lines[firstNonCommentLineIndex...])
    let cleanContent = cleanLines.joined(separator: "\n")

    return TestDataFile(expectedFields: expectedFields, expectedCategory: category, cleanContent: cleanContent)
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

/// 期待されるフィールドを取得（テストデータファイルから動的に読み込み）
@available(iOS 26.0, macOS 26.0, *)
public func getExpectedFields(for pattern: String, level: Int) -> [String] {
    // 有効なパターンとレベルの確認
    let validPatterns = ["Chat", "Contract", "CreditCard", "VoiceRecognition", "PasswordManager"]
    guard validPatterns.contains(pattern) && (1...3).contains(level) else {
        return []
    }

    // レベルに応じたサフィックスを取得
    let levelSuffix: String
    switch level {
    case 1: levelSuffix = "Basic"
    case 2: levelSuffix = "General"
    case 3: levelSuffix = "Complex"
    default: levelSuffix = "Basic"
    }

    // テストデータファイルのパスを構築
    let testDataPath = "Tests/TestData/\(pattern)/Level\(level)_\(levelSuffix).txt"

    // テストデータファイルから期待フィールドを読み込む
    do {
        let testDataFile = try parseTestDataFile(at: testDataPath)
        return testDataFile.expectedFields
    } catch {
        fatalError("❌ テストデータファイル '\(testDataPath)' の読み込みに失敗しました。エラー: \(error)")
    }
}

/// 期待されるカテゴリを取得（テストデータファイルから動的に読み込み）
/// @ai[2025-12-11 17:50] 期待カテゴリ取得関数を追加
/// @ai[2025-12-11 18:00] 戻り値を必須に変更（オプショナルを削除）
/// 目的: two-stepsモードでのカテゴリ判定精度を検証可能にする
/// 背景: テストケースファイルのヘッダで期待カテゴリを宣言（必須）
/// 意図: カテゴリ判定の正しさを客観的に評価する。期待カテゴリが指定されていない場合はparseTestDataFileでfatalErrorが発生する
@available(iOS 26.0, macOS 26.0, *)
public func getExpectedCategory(for pattern: String, level: Int) -> (mainCategory: String, subCategory: String) {
    // 有効なパターンとレベルの確認
    let validPatterns = ["Chat", "Contract", "CreditCard", "VoiceRecognition", "PasswordManager"]
    guard validPatterns.contains(pattern) && (1...3).contains(level) else {
        fatalError("❌ 無効なパターンまたはレベルです: pattern=\(pattern), level=\(level)")
    }

    // レベルに応じたサフィックスを取得
    let levelSuffix: String
    switch level {
    case 1: levelSuffix = "Basic"
    case 2: levelSuffix = "General"
    case 3: levelSuffix = "Complex"
    default: levelSuffix = "Basic"
    }

    // テストデータファイルのパスを構築
    let testDataPath = "Tests/TestData/\(pattern)/Level\(level)_\(levelSuffix).txt"

    // テストデータファイルから期待カテゴリを読み込む
    // expectedCategoryが指定されていない場合はparseTestDataFileでfatalErrorが発生する
    do {
        let testDataFile = try parseTestDataFile(at: testDataPath)
        return testDataFile.expectedCategory
    } catch {
        fatalError("❌ テストデータファイル '\(testDataPath)' の読み込みに失敗しました。エラー: \(error)")
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
    case "number": return accountInfo.number
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
