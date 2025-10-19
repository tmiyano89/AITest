import Foundation

/// @ai[2025-01-19 01:00] テストデータ読み込みユーティリティ
/// 目的: テストデータの読み込み処理を一元化
/// 背景: main.swiftの肥大化を防ぐため、テストデータ関連の処理を分離
/// 意図: 保守性の向上とコードの可読性向上

/// パターン名をテストデータディレクトリにマッピング
public func mapPatternToTestDataDirectory(_ pattern: String) -> String {
    // 実験パターンは全て同じテストデータを使用（Chat、Contract、CreditCard、VoiceRecognition、PasswordManager）
    return "TestData"
}

/// テストケースを読み込み
public func loadTestCases(pattern: String? = nil) -> [(name: String, text: String)] {
    var testCases: [(name: String, text: String)] = []
    
    // テストデータディレクトリのパスを取得
    let testDataDir = mapPatternToTestDataDirectory(pattern ?? "Chat")
    let bundle = Bundle.module
    guard let testDataPath = bundle.path(forResource: testDataDir, ofType: nil) else {
        print("❌ テストデータディレクトリが見つかりません: \(testDataDir)")
        return testCases
    }
    
    let fileManager = FileManager.default
    
    do {
        let files = try fileManager.contentsOfDirectory(atPath: testDataPath)
        let textFiles = files.filter { $0.hasSuffix(".txt") }.sorted()
        
        for file in textFiles {
            let filePath = "\(testDataPath)/\(file)"
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            let testCaseName = String(file.dropLast(4)) // .txtを除去
            testCases.append((name: testCaseName, text: content))
        }
        
        print("✅ テストケース読み込み完了: \(testCases.count)件")
    } catch {
        print("❌ テストケース読み込みエラー: \(error.localizedDescription)")
    }
    
    return testCases
}

/// 利用可能なパターンを取得
public func getAvailablePatterns(at basePath: String) -> [String] {
    let fileManager = FileManager.default
    
    do {
        let contents = try fileManager.contentsOfDirectory(atPath: basePath)
        return contents.filter { $0.hasSuffix(".txt") }
                      .map { String($0.dropLast(4)) } // .txtを除去
                      .sorted()
    } catch {
        print("❌ パターン取得エラー: \(error.localizedDescription)")
        return []
    }
}

/// 期待値回答を読み込み
public func loadExpectedAnswers() -> [String: [String: [String: String]]]? {
    guard let url = Bundle.module.url(forResource: "expected_answers", withExtension: "json") else {
        print("❌ expected_answers.jsonが見つかりません")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: url)
        let answers = try JSONSerialization.jsonObject(with: data) as? [String: [String: [String: String]]]
        print("✅ 期待値回答読み込み完了")
        return answers
    } catch {
        print("❌ 期待値回答読み込みエラー: \(error.localizedDescription)")
        return nil
    }
}
