#!/usr/bin/env swift

import Foundation
import FoundationModels
import AITest

/// @ai[2025-01-10 20:15] 有効なパターン名の定義
/// 目的: パターン名のリテラルを一元管理して保守性を向上
/// 背景: 複数箇所で同じパターン名が重複定義されており、変更時のリスクが高い
/// 意図: 単一の真実の源（Single Source of Truth）として定数で管理
let VALID_PATTERNS = ["Chat", "Contract", "CreditCard", "VoiceRecognition", "PasswordManager"]

/// @ai[2024-12-19 20:00] 処理時間計測ユーティリティ
/// 目的: 各関数の処理時間を計測してボトルネックを特定
/// 背景: 並列処理の効率性向上のため、詳細な性能分析が必要
/// 意図: リアルタイムでの処理時間監視とログ出力
class PerformanceTimer {
    private var startTime: Date?
    private let label: String
    
    init(_ label: String) {
        self.label = label
    }
    
    func start() {
        startTime = Date()
        print("⏱️  [\(label)] 開始")
    }
    
    func end() {
        guard let startTime = startTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        print("⏱️  [\(label)] 完了: \(String(format: "%.3f", duration))秒")
    }
    
    func checkpoint(_ message: String) {
        guard let startTime = startTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        print("⏱️  [\(label)] \(message): \(String(format: "%.3f", duration))秒")
    }
}

/// @ai[2024-12-19 19:30] AITest コンソールアプリケーション
/// 目的: FoundationModelsを使用したAccount情報抽出の性能測定をコンソールで実行
/// 背景: macOSコンソールアプリとして実行可能なライブラリベースの実装
/// 意図: 真のAI機能を使用した性能評価をmacOSで実行

print("🚀 AITest コンソールアプリケーション開始")
print("OS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)")
print(String(repeating: "=", count: 80))

// iOS 26+、macOS 26+の利用可能性チェック（メインターゲット）
if #available(iOS 26.0, macOS 26.0, *) {
    print("✅ iOS 26+ / macOS 26+ の要件を満たしています")
    
    // FoundationModelsの利用可能性をチェック
    print("🔍 FoundationModelsの利用可能性をチェック中...")
    
    let systemModel = SystemLanguageModel.default
    let availability = systemModel.availability
    
    print("🔍 SystemLanguageModel.availability: \(String(describing: availability))")
    
    switch availability {
    case .available:
        print("✅ AI利用可能 - ベンチマークを実行します")
        
        // タイムアウト設定（デフォルト: 300秒 = 5分）
        let timeoutSeconds = extractTimeoutFromArguments() ?? 300
        
        // デバッグモード: 単一テスト実行
        if CommandLine.arguments.contains("--debug-single") {
            await runWithTimeout(timeoutSeconds: timeoutSeconds) {
                await runSingleTestDebug()
            }
        } else if CommandLine.arguments.contains("--test-extraction-methods") {
        // 特定のexperimentを実行するかチェック
        print("🔍 コマンドライン引数をチェック中...")
        print("   引数: \(CommandLine.arguments)")
        
        if #available(iOS 26.0, macOS 26.0, *), let experiment = extractExperimentFromArguments() {
            print("✅ 特定のexperimentを検出: \(experiment.method.rawValue)_\(experiment.language.rawValue)")
            // テストディレクトリとパターンの取得
            let testDir = extractTestDirFromArguments()
            let pattern = extractPatternFromArguments()
            await runWithTimeout(timeoutSeconds: timeoutSeconds) {
                await runSpecificExperiment(experiment, testDir: testDir, pattern: pattern)
            }
        } else {
                print("⚠️ 特定のexperimentが指定されていません - デフォルトでyaml_enを実行")
                // デフォルトでyaml_enを実行
                let defaultExperiment = (method: ExtractionMethod.yaml, language: PromptLanguage.english)
                let testDir = extractTestDirFromArguments()
                let pattern = extractPatternFromArguments()
                await runWithTimeout(timeoutSeconds: timeoutSeconds) {
                    await runSpecificExperiment(defaultExperiment, testDir: testDir, pattern: pattern)
                }
            }
        } else {
            // 繰り返しベンチマーク実行
            await runWithTimeout(timeoutSeconds: timeoutSeconds) {
                await runRepeatedBenchmark()
            }
        }
        
    case .unavailable(.appleIntelligenceNotEnabled):
        print("❌ Apple Intelligenceが無効です")
        print("設定 > Apple Intelligence でApple Intelligenceを有効にしてください")
        
    case .unavailable(.deviceNotEligible):
        print("❌ このデバイスではAIモデルを利用できません")
        print("iPhone 15 Pro以降、またはM1以降のMacが必要です")
        
    case .unavailable(.modelNotReady):
        print("❌ AIモデルをダウンロード中です")
        print("モデルのダウンロードが完了するまでお待ちください")
        
    case .unavailable(let reason):
        print("❌ Apple Intelligence利用不可: \(String(describing: reason))")
    }
    
} else {
    print("❌ iOS 26+ または macOS 26+ が必要です")
    print("現在のOSバージョン: \(ProcessInfo.processInfo.operatingSystemVersionString)")
    print("FoundationModelsは利用できません")
    
    // iOS 18.2+での動作確認
    print("📱 iOS 18.2+での動作確認")
    print("⚠️ アプリは起動しますが、AI機能は利用できません")
    print("⚠️ エラーメッセージが表示されることを確認してください")
}

print(String(repeating: "=", count: 80))
print("✅ AITest コンソールアプリケーション完了")

/// 抽出方法比較テスト実行関数
@available(iOS 26.0, macOS 26.0, *)
@MainActor
func runExtractionMethodComparison() async {
    print("\n🔬 抽出方法比較テストを開始")
    print("🔄 各抽出方法で同じテストケースを実行し、性能を比較します")
    print(String(repeating: "-", count: 60))
    
    // テストケースの読み込み
    let testCases = loadTestCases()
    
    for (index, testCase) in testCases.enumerated() {
        print("\n📋 テストケース \(index + 1): \(testCase.name)")
        print("📝 入力テキスト: \(testCase.text.prefix(100))...")
        print(String(repeating: "-", count: 40))
        
        // 各抽出方法と各言語でテスト実行
        for method in ExtractionMethod.allCases {
            for language in PromptLanguage.allCases {
                print("\n🔍 抽出方法: \(method.displayName) (\(language.displayName))")
                print("📝 説明: \(method.description) - \(language.description)")
                
                do {
                    let extractor = AccountExtractor()
                    let (accountInfo, metrics) = try await extractor.extractFromText(testCase.text, method: method, language: language)
                
                print("✅ 抽出成功")
                print("  ⏱️  抽出時間: \(String(format: "%.3f", metrics.extractionTime))秒")
                print("  ⏱️  総時間: \(String(format: "%.3f", metrics.totalTime))秒")
                print("  💾 メモリ使用量: \(String(format: "%.2f", metrics.memoryUsed))MB")
                print("  📊 抽出フィールド数: \(accountInfo.extractedFieldsCount)")
                print("  🎯 信頼度: \(String(format: "%.2f", accountInfo.confidence ?? 0))")
                print("  ✅ バリデーション: \(metrics.isValid ? "成功" : "警告あり")")
                
                // 抽出されたフィールドの詳細表示
                print("  📋 抽出結果:")
                if let title = accountInfo.title { print("    title: \(title)") }
                if let userID = accountInfo.userID { print("    userID: \(userID)") }
                if let password = accountInfo.password { print("    password: \(password)") }
                if let url = accountInfo.url { print("    url: \(url)") }
                if let note = accountInfo.note { print("    note: \(note.prefix(50))...") }
                if let host = accountInfo.host { print("    host: \(host)") }
                if let port = accountInfo.port { print("    port: \(port)") }
                if let authKey = accountInfo.authKey { print("    authKey: \(authKey.prefix(50))...") }
                
                } catch {
                    print("❌ 抽出失敗: \(error.localizedDescription)")
                }
            }
        }
        
        print(String(repeating: "=", count: 60))
    }
    
    print("\n📊 抽出方法比較テスト完了")
    
    // HTMLレポート生成
    await generateFormatExperimentReport()
}

/// フォーマット実験レポートを生成
@available(iOS 26.0, macOS 26.0, *)
@MainActor
func generateFormatExperimentReport() async {
    print("\n📄 フォーマット実験レポートを生成中...")
    
    let testCases = loadTestCases()
    var reportData: [(testCase: String, method: String, language: String, result: String, metrics: String)] = []
    
    for testCase in testCases {
        for method in ExtractionMethod.allCases {
            for language in PromptLanguage.allCases {
                do {
                    let extractor = AccountExtractor()
                    let (accountInfo, metrics) = try await extractor.extractFromText(testCase.text, method: method, language: language)
                    
                    let result = """
                    title: \(accountInfo.title ?? "nil")
                    userID: \(accountInfo.userID ?? "nil")
                    password: \(accountInfo.password ?? "nil")
                    url: \(accountInfo.url ?? "nil")
                    note: \(accountInfo.note ?? "nil")
                    host: \(accountInfo.host ?? "nil")
                    port: \(accountInfo.port?.description ?? "nil")
                    authKey: \(accountInfo.authKey ?? "nil")
                    confidence: \(accountInfo.confidence?.description ?? "nil")
                    """
                    
                    let metricsStr = """
                    抽出時間: \(String(format: "%.3f", metrics.extractionTime))秒
                    総時間: \(String(format: "%.3f", metrics.totalTime))秒
                    メモリ使用量: \(String(format: "%.2f", metrics.memoryUsed))MB
                    抽出フィールド数: \(accountInfo.extractedFieldsCount)
                    バリデーション: \(metrics.isValid ? "成功" : "警告あり")
                    """
                    
                    reportData.append((
                        testCase: testCase.name,
                        method: "\(method.displayName) (\(language.displayName))",
                        language: language.displayName,
                        result: result,
                        metrics: metricsStr
                    ))
                    
                } catch {
                    let errorResult = "エラー: \(error.localizedDescription)"
                    let errorMetrics = "抽出失敗"
                    
                    reportData.append((
                        testCase: testCase.name,
                        method: "\(method.displayName) (\(language.displayName))",
                        language: language.displayName,
                        result: errorResult,
                        metrics: errorMetrics
                    ))
                }
            }
        }
    }
    
    // HTMLレポート生成
    let htmlContent = generateHTMLReport(data: reportData)
    
    do {
        try htmlContent.write(toFile: "reports/format_experiment_report.html", atomically: true, encoding: .utf8)
        print("✅ フォーマット実験レポートを生成しました: reports/format_experiment_report.html")
    } catch {
        print("❌ HTMLレポート生成エラー: \(error.localizedDescription)")
    }
}

/// HTMLレポートを生成
func generateHTMLReport(data: [(testCase: String, method: String, language: String, result: String, metrics: String)]) -> String {
    let timestamp = DateFormatter().string(from: Date())
    
    var html = """
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>FoundationModels フォーマット実験レポート</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
            .test-case { margin-bottom: 30px; border: 1px solid #ddd; border-radius: 8px; overflow: hidden; }
            .test-case-header { background: #f8f9fa; padding: 15px; font-weight: bold; font-size: 1.2em; }
            .method-group { margin: 10px 0; }
            .method-header { background: #e9ecef; padding: 10px; font-weight: bold; }
            .result-content { padding: 15px; background: #f8f9fa; }
            .metrics { padding: 10px; background: #e9ecef; font-family: monospace; font-size: 0.9em; }
            .error { color: #dc3545; background: #f8d7da; padding: 10px; border-radius: 4px; }
            pre { white-space: pre-wrap; word-wrap: break-word; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🔬 FoundationModels フォーマット実験レポート</h1>
            <p>生成日時: \(timestamp)</p>
            <p>総テストケース数: \(data.count)</p>
        </div>
    """
    
    // テストケースごとにグループ化
    let groupedData = Dictionary(grouping: data) { $0.testCase }
    
    for (testCase, results) in groupedData.sorted(by: { $0.key < $1.key }) {
        html += """
        <div class="test-case">
            <div class="test-case-header">📋 \(testCase)</div>
        """
        
        // 抽出方法ごとにグループ化
        let methodGroups = Dictionary(grouping: results) { $0.method }
        
        for (method, methodResults) in methodGroups.sorted(by: { $0.key < $1.key }) {
            html += """
            <div class="method-group">
                <div class="method-header">🔍 \(method)</div>
            """
            
            for result in methodResults {
                let isError = result.result.contains("エラー:")
                let resultClass = isError ? "error" : "result-content"
                
                html += """
                <div class="\(resultClass)">
                    <h4>言語: \(result.language)</h4>
                    <h5>抽出結果:</h5>
                    <pre>\(result.result)</pre>
                    <h5>メトリクス:</h5>
                    <div class="metrics">\(result.metrics)</div>
                </div>
                """
            }
            
            html += "</div>"
        }
        
        html += "</div>"
    }
    
    html += """
        <div class="header">
            <h2>📊 実験完了</h2>
            <p>@ai[2024-12-19 17:45] FoundationModels フォーマット実験レポート</p>
        </div>
    </body>
    </html>
    """
    
    return html
}

/// コマンドライン引数からタイムアウト時間を抽出
func extractTimeoutFromArguments() -> Int? {
    for argument in CommandLine.arguments {
        if argument.hasPrefix("--timeout=") {
            let timeoutString = String(argument.dropFirst("--timeout=".count))
            return Int(timeoutString)
        }
    }
    return nil
}

/// コマンドライン引数からパターン指定を抽出
func extractPatternFromArguments() -> String? {
    for argument in CommandLine.arguments {
        if argument.hasPrefix("--pattern=") {
            return String(argument.dropFirst("--pattern=".count))
        }
    }
    return nil
}

/// コマンドライン引数からexperimentを抽出
@available(iOS 26.0, macOS 26.0, *)
func extractExperimentFromArguments() -> (method: ExtractionMethod, language: PromptLanguage)? {
    print("🔍 extractExperimentFromArguments 開始")
    print("   利用可能なExtractionMethod: \(ExtractionMethod.allCases.map { $0.rawValue })")
    print("   利用可能なPromptLanguage: \(PromptLanguage.allCases.map { $0.rawValue })")
    
    // --experiment= の形式をチェック
    for argument in CommandLine.arguments {
        if argument.hasPrefix("--experiment=") {
            let experimentString = String(argument.dropFirst("--experiment=".count))
            print("   --experiment= 形式を検出: \(experimentString)")
            let components = experimentString.split(separator: "_")
            print("   コンポーネント: \(components)")
            
            guard components.count == 2,
                  let method = ExtractionMethod.allCases.first(where: { $0.rawValue == String(components[0]) }),
                  let language = PromptLanguage.allCases.first(where: { $0.rawValue == String(components[1]) }) else {
                print("❌ 無効なexperiment指定: \(experimentString)")
                print("   有効な形式: --experiment=generable_japanese")
                return nil
            }
            
            print("✅ experimentを抽出: \(method.rawValue)_\(language.rawValue)")
            return (method: method, language: language)
        }
    }
    
    // --experiment の形式をチェック（次の引数を取得）
    for (index, argument) in CommandLine.arguments.enumerated() {
        if argument == "--experiment" && index + 1 < CommandLine.arguments.count {
            let experimentString = CommandLine.arguments[index + 1]
            print("   --experiment 形式を検出: \(experimentString)")
            let components = experimentString.split(separator: "_")
            print("   コンポーネント: \(components)")
            
            guard components.count == 2,
                  let method = ExtractionMethod.allCases.first(where: { $0.rawValue == String(components[0]) }),
                  let language = PromptLanguage.allCases.first(where: { $0.rawValue == String(components[1]) }) else {
                print("❌ 無効なexperiment指定: \(experimentString)")
                print("   有効な形式: --experiment generable_japanese")
                return nil
            }
            
            print("✅ experimentを抽出: \(method.rawValue)_\(language.rawValue)")
            return (method: method, language: language)
        }
    }
    
    print("❌ experimentが見つかりませんでした")
    return nil
}

/// コマンドライン引数からテストディレクトリを抽出
func extractTestDirFromArguments() -> String? {
    for argument in CommandLine.arguments {
        if argument.hasPrefix("--test-dir=") {
            return String(argument.dropFirst("--test-dir=".count))
        }
    }
    return nil
}

/// タイムアウト付きでタスクを実行
@available(iOS 26.0, macOS 26.0, *)
func runWithTimeout(timeoutSeconds: Int, task: @escaping @Sendable () async -> Void) async {
    print("⏱️ タイムアウト設定: \(timeoutSeconds)秒")
    
    await withTaskGroup(of: Void.self) { group in
        // メインタスク
        group.addTask {
            await task()
        }
        
        // タイムアウトタスク
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds) * 1_000_000_000)
            print("⏰ タイムアウト: \(timeoutSeconds)秒経過")
            print("🛑 処理を中断します")
        }
        
        // 最初に完了したタスクを待つ
        await group.next()
        group.cancelAll()
    }
}

/// テストケースを読み込み
func loadTestCases(pattern: String? = nil) -> [(name: String, text: String)] {
    var testCases: [(name: String, text: String)] = []
    
    // テストデータファイルのパス
    let testDataBasePath = "/Users/t.miyano/repos/AITest/Tests/TestData"
    
    // パターン指定がある場合はそのパターンのみ、ない場合は全パターン
    let scenarios: [String]
    if let pattern = pattern {
        scenarios = [normalizePatternName(pattern)]
    } else {
        scenarios = VALID_PATTERNS
    }
    
    let levels = ["Level1_Basic", "Level2_General", "Level3_Complex"]
    
    // テストデータディレクトリの存在確認
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: testDataBasePath) else {
        assertionFailure("テストデータディレクトリが見つかりません: \(testDataBasePath)")
        return []
    }
    
    for scenario in scenarios {
        let scenarioPath = "\(testDataBasePath)/\(scenario)"
        guard fileManager.fileExists(atPath: scenarioPath) else {
            print("⚠️ パターンディレクトリが見つかりません: \(scenarioPath)")
            assertionFailure("パターンディレクトリが見つかりません: \(scenarioPath)。利用可能なパターン: \(getAvailablePatterns(at: testDataBasePath))")
            continue
        }
        
        for level in levels {
            let fileName = "\(level).txt"
            let filePath = "\(scenarioPath)/\(fileName)"
            
            do {
                let content = try String(contentsOfFile: filePath, encoding: .utf8)
                // ファイルが空でないことを確認
                guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    print("⚠️ テストデータファイルが空です: \(filePath)")
                    assertionFailure("テストデータファイルが空です: \(filePath)")
                    continue
                }
                
                let levelName = level.replacingOccurrences(of: "_", with: " ")
                let testName = "\(scenario) \(levelName)"
                testCases.append((name: testName, text: content))
            } catch {
                print("⚠️ テストデータファイル読み込みエラー: \(filePath)")
                print("   エラー: \(error.localizedDescription)")
                assertionFailure("テストデータファイルの読み込みに失敗しました: \(filePath)。エラー: \(error.localizedDescription)")
            }
        }
    }
    
    // 読み込まれたテストケース数の確認
    guard !testCases.isEmpty else {
        assertionFailure("テストケースが1つも読み込まれませんでした。テストデータファイルの存在と形式を確認してください。")
        return []
    }
    
    print("✅ テストケース読み込み完了: \(testCases.count)件")
    return testCases
}

/// 利用可能なパターンを取得
func getAvailablePatterns(at basePath: String) -> [String] {
    let fileManager = FileManager.default
    do {
        let contents = try fileManager.contentsOfDirectory(atPath: basePath)
        return contents.filter { fileManager.fileExists(atPath: "\(basePath)/\($0)") && $0 != "expected_answers.json" }
    } catch {
        return []
    }
}

/// 特定のexperimentを実行
@available(iOS 26.0, macOS 26.0, *)
@MainActor
func runSpecificExperiment(_ experiment: (method: ExtractionMethod, language: PromptLanguage), testDir: String?, pattern: String? = nil) async {
    let timer = PerformanceTimer("特定実験全体")
    timer.start()
    
    print("\n🔬 特定実験を開始: \(experiment.method.displayName) (\(experiment.language.displayName))")
    if let pattern = pattern {
        print("📋 パターン指定: \(pattern)")
    }
    print("🔄 指定された抽出方法・言語のみを実行します")
    print(String(repeating: "-", count: 60))
    
    // テスト実行用のディレクトリを決定
    let finalTestDir: String
    if let providedTestDir = testDir {
        finalTestDir = providedTestDir
    } else {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        let timestamp = formatter.string(from: Date())
        finalTestDir = "test_\(timestamp)"
    }
    createLogDirectory(finalTestDir)
    timer.checkpoint("ディレクトリ作成完了")
    
    // テストケースの読み込み
    let testCases = loadTestCases(pattern: pattern)
    timer.checkpoint("テストケース読み込み完了")
    
    // パターン・レベルごとのiteration番号を管理
    var iterationCounters: [String: Int] = [:]
    
    for (index, testCase) in testCases.enumerated() {
        let testTimer = PerformanceTimer("テストケース\(index + 1)")
        testTimer.start()
        
        print("\n📋 テストケース \(index + 1): \(testCase.name)")
        print("📝 入力テキスト: \(testCase.text.prefix(100))...")
        print(String(repeating: "-", count: 40))
        
        // デバッグ: 期待値の取得をテスト
        print("🔍 期待値取得テスト:")
        let (pattern, level) = parseTestCaseName(testCase.name)
        let expectedFields = getExpectedFields(for: pattern, level: level)
        for field in expectedFields {
            let expectedValue = getExpectedValue(for: field, testCaseName: testCase.name)
            print("  \(field): '\(expectedValue)'")
        }
        
        print("\n🔍 抽出方法: \(experiment.method.displayName) (\(experiment.language.displayName))")
        print("📝 説明: \(experiment.method.description) - \(experiment.language.description)")
        
        // パターン・レベルごとのiteration番号を取得
        let key = "\(pattern)_level\(level)"
        iterationCounters[key, default: 0] += 1
        let iteration = iterationCounters[key]!
        
        do {
            let extractor = AccountExtractor()
            testTimer.checkpoint("抽出器作成完了")
            
            let (accountInfo, metrics) = try await extractor.extractFromText(testCase.text, method: experiment.method, language: experiment.language)
            testTimer.checkpoint("AI抽出完了")
        
            print("✅ 抽出成功")
            print("  ⏱️  抽出時間: \(String(format: "%.3f", metrics.extractionTime))秒")
            print("  ⏱️  総時間: \(String(format: "%.3f", metrics.totalTime))秒")
            print("  📊 抽出フィールド数: \(accountInfo.extractedFieldsCount)")
            print("  ✅ バリデーション: \(metrics.isValid ? "成功" : "警告あり")")
            
            // 抽出されたフィールドの詳細表示
            print("  📋 抽出結果:")
            if let title = accountInfo.title { print("    title: \(title)") }
            if let userID = accountInfo.userID { print("    userID: \(userID)") }
            if let password = accountInfo.password { print("    password: \(password)") }
            if let url = accountInfo.url { print("    url: \(url)") }
            if let note = accountInfo.note { print("    note: \(note)") }
            if let host = accountInfo.host { print("    host: \(host)") }
            if let port = accountInfo.port { print("    port: \(port)") }
            if let authKey = accountInfo.authKey { print("    authKey: \(authKey)") }
            
            // 構造化ログの出力
            await generateStructuredLog(testCase: testCase, accountInfo: accountInfo, experiment: experiment, iteration: iteration, testDir: finalTestDir)
            testTimer.checkpoint("ログ出力完了")
            
        } catch {
            print("❌ 抽出失敗: \(error.localizedDescription)")
            
            // エラー時の構造化ログ
            await generateErrorStructuredLog(testCase: testCase, error: error, experiment: experiment, iteration: iteration, testDir: finalTestDir)
            testTimer.checkpoint("エラーログ出力完了")
        }
        
        testTimer.end()
        print(String(repeating: "=", count: 60))
    }
    
    // HTMLレポートの生成
    await generateFormatExperimentReport(testDir: finalTestDir, experiment: experiment, testCases: testCases)
    timer.checkpoint("HTMLレポート生成完了")
    
    timer.end()
    print("\n📊 特定実験完了")
    print("📁 テスト結果: \(finalTestDir)/")
}

/// フォーマット実験レポートを生成
@available(iOS 26.0, macOS 26.0, *)
func generateFormatExperimentReport(testDir: String, experiment: (method: ExtractionMethod, language: PromptLanguage), testCases: [(name: String, text: String)]) async {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let timestamp = formatter.string(from: Date())
    
    var htmlContent = """
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>FoundationModels フォーマット実験レポート</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
            .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }
            .summary-card { background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; }
            .test-case { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }
            .test-case h3 { margin-top: 0; color: #333; }
            .result { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
            .success { border-left: 4px solid #28a745; }
            .error { border-left: 4px solid #dc3545; }
            .field { margin: 5px 0; padding: 5px; background: #e9ecef; border-radius: 3px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🔬 FoundationModels フォーマット実験レポート</h1>
            <p>生成日時: \(timestamp)</p>
            <p>抽出方法: \(experiment.method.displayName)</p>
            <p>言語: \(experiment.language.displayName)</p>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>テストケース数</h3>
                <p style="font-size: 2em; margin: 0;">\(testCases.count)</p>
            </div>
            <div class="summary-card">
                <h3>抽出方法</h3>
                <p style="font-size: 1.5em; margin: 0;">\(experiment.method.displayName)</p>
            </div>
            <div class="summary-card">
                <h3>言語</h3>
                <p style="font-size: 1.5em; margin: 0;">\(experiment.language.displayName)</p>
            </div>
        </div>
    """
    
    // 各テストケースの結果を追加
    for (index, testCase) in testCases.enumerated() {
        htmlContent += """
        <div class="test-case">
            <h3>📋 テストケース \(index + 1): \(testCase.name)</h3>
            <div class="result">
                <h4>入力テキスト:</h4>
                <pre>\(testCase.text)</pre>
            </div>
            <div class="result">
                <h4>抽出結果:</h4>
                <p>詳細な抽出結果は個別のJSONログファイルを確認してください。</p>
            </div>
        </div>
        """
    }
    
    htmlContent += """
        </body>
    </html>
    """
    
    // HTMLファイルを保存
    let htmlFilePath = "\(testDir)/\(experiment.method.rawValue)_\(experiment.language.rawValue)_format_experiment_report.html"
    do {
        try htmlContent.write(toFile: htmlFilePath, atomically: true, encoding: .utf8)
        print("📄 HTMLレポート生成: \(htmlFilePath)")
    } catch {
        print("❌ HTMLレポート生成エラー: \(error.localizedDescription)")
    }
}

/// ログディレクトリを作成
func createLogDirectory(_ path: String) {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: path) {
        try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }
}

/// 構造化ログを生成
@available(iOS 26.0, macOS 26.0, *)
func generateStructuredLog(testCase: (name: String, text: String), accountInfo: AccountInfo, experiment: (method: ExtractionMethod, language: PromptLanguage), iteration: Int, testDir: String) async {
    let (pattern, level) = parseTestCaseName(testCase.name)
    let expectedFields = getExpectedFields(for: pattern, level: level)
    
    var structuredLog: [String: Any] = [
        "pattern": pattern,
        "level": level,
        "iteration": iteration,
        "method": experiment.method.rawValue,
        "language": experiment.language.rawValue,
        "expected_fields": [],
        "unexpected_fields": []
    ]
    
    // 期待されるフィールドの分析
    var expectedFieldsArray: [[String: Any]] = []
    for field in expectedFields {
        let extractedValue = getFieldValue(accountInfo, fieldName: field)
        let expectedValue = getExpectedValue(for: field, testCaseName: testCase.name)
        let status = determineFieldStatus(fieldName: field, extractedValue: extractedValue, expectedValue: expectedValue)
        
        expectedFieldsArray.append([
            "name": field,
            "value": extractedValue ?? NSNull(),
            "status": status
        ])
    }
    structuredLog["expected_fields"] = expectedFieldsArray
    
    // 期待されないフィールドの分析（実際に抽出された項目のみ記載）
    var unexpectedFieldsArray: [[String: Any]] = []
    let allFields = ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
    for field in allFields {
        if !expectedFields.contains(field) {
            if let value = getFieldValue(accountInfo, fieldName: field), !value.isEmpty {
                unexpectedFieldsArray.append([
                    "name": field,
                    "value": value,
                    "status": "unexpected"
                ])
            }
        }
    }
    structuredLog["unexpected_fields"] = unexpectedFieldsArray
    
    // JSONログを出力
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: structuredLog, options: .prettyPrinted)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("\n📊 構造化ログ:")
            print(jsonString)
            
            // ログファイルに保存
            let logFileName = "\(experiment.method.rawValue)_\(experiment.language.rawValue)_\(pattern)_level\(level)_\(iteration).json"
            let logFilePath = "\(testDir)/\(logFileName)"
            try jsonString.write(toFile: logFilePath, atomically: true, encoding: .utf8)
            print("💾 ログ保存: \(logFilePath)")
        }
    } catch {
        print("❌ 構造化ログ生成エラー: \(error.localizedDescription)")
    }
}

/// エラー時の構造化ログを生成
@available(iOS 26.0, macOS 26.0, *)
func generateErrorStructuredLog(testCase: (name: String, text: String), error: Error, experiment: (method: ExtractionMethod, language: PromptLanguage), iteration: Int, testDir: String) async {
    let (pattern, level) = parseTestCaseName(testCase.name)
    let expectedFields = getExpectedFields(for: pattern, level: level)
    
    var structuredLog: [String: Any] = [
        "pattern": pattern,
        "level": level,
        "iteration": iteration,
        "method": experiment.method.rawValue,
        "language": experiment.language.rawValue,
        "error": error.localizedDescription,
        "expected_fields": [],
        "unexpected_fields": []
    ]
    
    // エラー時は全ての期待フィールドをmissingとして記録
    var expectedFieldsArray: [[String: Any]] = []
    for field in expectedFields {
        expectedFieldsArray.append([
            "name": field,
            "value": NSNull(),
            "status": "missing"
        ])
    }
    structuredLog["expected_fields"] = expectedFieldsArray
    structuredLog["unexpected_fields"] = []
    
    // JSONログを出力
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: structuredLog, options: .prettyPrinted)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("\n📊 構造化ログ（エラー）:")
            print(jsonString)
            
            // ログファイルに保存
            let logFileName = "\(experiment.method.rawValue)_\(experiment.language.rawValue)_\(pattern)_level\(level)_\(iteration)_error.json"
            let logFilePath = "\(testDir)/\(logFileName)"
            try jsonString.write(toFile: logFilePath, atomically: true, encoding: .utf8)
            print("💾 エラーログ保存: \(logFilePath)")
        }
    } catch {
        print("❌ 構造化ログ生成エラー: \(error.localizedDescription)")
    }
}

/// パターン名を正規化（大文字小文字を無視して正しい形式に変換）
func normalizePatternName(_ pattern: String) -> String {
    // 大文字小文字を無視して比較
    for validPattern in VALID_PATTERNS {
        if pattern.lowercased() == validPattern.lowercased() {
            return validPattern
        }
    }
    
    // マッチしない場合は元の文字列を返す（エラーハンドリングは呼び出し元で行う）
    return pattern
}

/// テストケース名からパターンとレベルを解析
func parseTestCaseName(_ name: String) -> (pattern: String, level: Int) {
    let components = name.split(separator: " ")
    let pattern = String(components[0]) // 大文字小文字を保持
    
    // "Level1 Basic" の形式からレベルを抽出
    if components.count >= 2 {
        let levelString = String(components[1])
        if levelString.hasPrefix("Level") {
            let level = Int(levelString.replacingOccurrences(of: "Level", with: "")) ?? 1
            return (pattern: pattern, level: level)
        }
    }
    
    // フォールバック: デフォルトでレベル1
    return (pattern: pattern, level: 1)
}

/// パターンとレベルに基づいて期待フィールドを取得
func getExpectedFields(for pattern: String, level: Int) -> [String] {
    // 有効なパターンとレベルの確認
    let validLevels = [1, 2, 3]
    
    guard VALID_PATTERNS.contains(pattern) else {
        assertionFailure("無効なパターンです: \(pattern)。有効なパターン: \(VALID_PATTERNS)")
        return []
    }
    
    guard validLevels.contains(level) else {
        assertionFailure("無効なレベルです: \(level)。有効なレベル: \(validLevels)")
        return []
    }
    
    switch pattern {
    case "Chat":
        switch level {
        case 1: return ["title", "userID", "password", "note"]
        case 2: return ["title", "userID", "password", "url", "note", "port"]
        case 3: return ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
        default: 
            assertionFailure("Chatパターンの無効なレベルです: \(level)")
            return ["title", "userID", "password", "note"]
        }
    case "Contract":
        switch level {
        case 1: return ["title", "userID", "password", "note"]
        case 2: return ["title", "userID", "password", "url", "note"]
        case 3: return ["title", "userID", "password", "url", "note", "host", "port" , "authKey"]
        default: 
            assertionFailure("Contractパターンの無効なレベルです: \(level)")
            return ["title", "userID", "password", "note"]
        }
    case "CreditCard":
        switch level {
        case 1: return ["title", "userID", "note"]
        case 2: return ["title", "userID", "note"]
        case 3: return ["title", "userID", "note"]
        default: 
            assertionFailure("CreditCardパターンの無効なレベルです: \(level)")
            return ["title", "userID", "note"]
        }
    case "VoiceRecognition":
        switch level {
        case 1: return ["title", "userID", "password", "note"]
        case 2: return ["title", "userID", "password", "note", "url", "port"]
        case 3: return ["title", "userID", "password", "note", "url", "host", "port", "authKey"]
        default: 
            assertionFailure("VoiceRecognitionパターンの無効なレベルです: \(level)")
            return ["title", "userID", "password", "note"]
        }
    case "PasswordManager":
        switch level {
        case 1: return ["title", "userID", "password", "note", "url"]
        case 2: return ["title", "userID", "password", "note", "url"]
        case 3: return ["title", "userID", "password", "note", "url", "host", "port", "authKey"]
        default: 
            assertionFailure("PasswordManagerパターンの無効なレベルです: \(level)")
            return ["title", "userID", "password", "note", "url"]
        }
    default:
        assertionFailure("未定義のパターンです: \(pattern)")
        return ["title", "userID", "password", "note"]
    }
}

/// AccountInfoから指定フィールドの値を取得
@available(iOS 26.0, macOS 26.0, *)
func getFieldValue(_ accountInfo: AccountInfo, fieldName: String) -> String? {
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

/// テストケース名から期待値を取得
func getExpectedValue(for fieldName: String, testCaseName: String) -> String {
    let (pattern, level) = parseTestCaseName(testCaseName)
    let levelName = "Level\(level)_\(level == 1 ? "Basic" : level == 2 ? "General" : "Complex")"
    
    // 正解データを読み込み
    guard let expectedAnswers = loadExpectedAnswers() else {
        print("❌ 正解データの読み込みに失敗")
        assertionFailure("expected_answers.jsonの読み込みに失敗しました。ファイルが存在し、正しい形式であることを確認してください。")
        return ""
    }
    
    // パターンとレベルに基づいて期待値を取得
    guard let patternData = expectedAnswers[pattern] else {
        print("❌ パターンデータが見つかりません: \(pattern)")
        assertionFailure("期待されるパターン '\(pattern)' がexpected_answers.jsonに見つかりません。利用可能なパターン: \(Array(expectedAnswers.keys))")
        return ""
    }
    
    guard let levelData = patternData[levelName] else {
        print("❌ レベルデータが見つかりません: \(levelName)")
        assertionFailure("期待されるレベル '\(levelName)' がパターン '\(pattern)' に見つかりません。利用可能なレベル: \(Array(patternData.keys))")
        return ""
    }
    
    guard let expectedValue = levelData[fieldName] else {
        print("❌ フィールドが見つかりません: \(fieldName)")
        assertionFailure("期待されるフィールド '\(fieldName)' がレベル '\(levelName)' に見つかりません。利用可能なフィールド: \(Array(levelData.keys))")
        return ""
    }
    
    return expectedValue
}

/// 正解データを読み込み
func loadExpectedAnswers() -> [String: [String: [String: String]]]? {
    guard let url = Bundle.module.url(forResource: "expected_answers", withExtension: "json") else {
        print("❌ expected_answers.jsonが見つかりません")
        assertionFailure("expected_answers.jsonファイルがBundle.moduleから見つかりません。Package.swiftでリソースが正しく設定されているか確認してください。")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: url)
        guard let expectedAnswers = try JSONSerialization.jsonObject(with: data) as? [String: [String: [String: String]]] else {
            print("❌ 正解データの型変換に失敗")
            assertionFailure("expected_answers.jsonの形式が正しくありません。期待される形式: [String: [String: [String: String]]]")
            return nil
        }
        
        // データの整合性をチェック
        let missingPatterns = VALID_PATTERNS.filter { !expectedAnswers.keys.contains($0) }
        if !missingPatterns.isEmpty {
            print("❌ 必須パターンが不足しています: \(missingPatterns)")
            assertionFailure("expected_answers.jsonに必須パターンが不足しています: \(missingPatterns)。利用可能なパターン: \(Array(expectedAnswers.keys))")
        }
        
        return expectedAnswers
    } catch {
        print("❌ 正解データの解析に失敗: \(error)")
        assertionFailure("expected_answers.jsonの読み込みまたは解析に失敗しました: \(error.localizedDescription)")
        return nil
    }
}

/// フィールドの状態を判定
func determineFieldStatus(fieldName: String, extractedValue: String?, expectedValue: String) -> String {
    guard let extracted = extractedValue else {
        return "missing"
    }
    
    // 空文字列は欠落として扱う
    if extracted.isEmpty {
        return "missing"
    }
        
    // AIによる検証が必要な項目かどうかをチェック
    if requiresAIVerification(fieldName: fieldName, extractedValue: extracted) {
        return "pending"
    }
    
    // プログラム的に判定する項目は完全一致が原則    
    if extracted == expectedValue {
        return "correct"
    } else {
        return "wrong"
    }
}

/// AIによる検証が必要かどうかを判定
func requiresAIVerification(fieldName: String, extractedValue: String) -> Bool {
    switch fieldName {
    case "title":
        // タイトルは自由形式の記述が可能（様々な表現が正しい場合がある）
        return true
    case "note":
        // 備考は自由形式の記述が可能（様々な表現が正しい場合がある）
        return true
    case "host":
        // ホスト名はIPアドレスかドメイン名の2択で形式が明確
        return false
    case "userID":
        // ユーザーIDは特定の値で完全一致が必要
        return false
    case "password":
        // パスワードは特定の値で完全一致が必要
        return false
    case "url":
        // URLは特定の値で完全一致が必要
        return false
    case "port":
        // ポート番号は特定の値で完全一致が必要
        return false
    case "authKey":
        // 認証キーは特定の値で完全一致が必要
        return false
    default:
        // その他の項目は特定の値で完全一致が必要
        return false
    }
}

/// 繰り返しベンチマーク実行関数
@available(iOS 26.0, macOS 26.0, *)
@MainActor
func runRepeatedBenchmark() async {
    print("\n🎯 繰り返しAccount情報抽出ベンチマークを開始")
    print("🔄 各テストを3回繰り返し実行します")
    print(String(repeating: "-", count: 60))

    do {
        let benchmark = RepeatedBenchmark()
        try await benchmark.runRepeatedBenchmark()

        print("\n📊 繰り返しベンチマーク結果:")
        print(String(repeating: "-", count: 40))

        // 各テストの結果を表示
        for (testIndex, testResult) in benchmark.results.enumerated() {
            let testName = getTestName(testIndex: testIndex)
            print("テスト \(testIndex + 1): \(testName)")
            print("  成功率: \(String(format: "%.1f", testResult.successRate * 100))%")
            print("  平均抽出時間: \(String(format: "%.3f", testResult.averageExtractionTime))秒")
            print("  平均信頼度: \(String(format: "%.2f", testResult.averageConfidence))")
            print("  実行回数: \(testResult.totalRuns)")
            print("  成功回数: \(testResult.successfulRuns)")
            
            // 項目レベル分析を表示
            print("  📊 項目別成功率:")
            let fields = ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
            for field in fields {
                let successRate = testResult.fieldAnalysis.fieldSuccessRates[field] ?? 0.0
                let extractionCount = testResult.fieldAnalysis.fieldExtractionCounts[field] ?? 0
                let errorCount = testResult.fieldAnalysis.fieldErrorCounts[field] ?? 0
                let characterAccuracy = testResult.fieldAnalysis.fieldCharacterAccuracy[field] ?? 0.0
                let expectedValue = testResult.fieldAnalysis.fieldExpectedValues[field]
                
                // 含まれていない項目は表示しない
                guard extractionCount > 0 || expectedValue != nil else { continue }
                
                var fieldInfo = "    \(field): \(String(format: "%.1f", successRate * 100))% (抽出:\(extractionCount), エラー:\(errorCount))"
                
                // 文字レベル精度を表示
                if characterAccuracy > 0 {
                    let accuracyPercent = String(format: "%.1f", characterAccuracy * 100)
                    fieldInfo += " [文字精度:\(accuracyPercent)%]"
                }
                
                // 期待値を表示
                if let expected = expectedValue {
                    fieldInfo += " [期待値:\(String(describing: expected))]"
                }
                
                print(fieldInfo)
            }
            
            // note内容分析を表示
            if testResult.fieldAnalysis.noteContentAnalysis.totalNoteExtractions > 0 {
                print("  📝 note内容分析:")
                print("    多様性スコア: \(String(format: "%.2f", testResult.fieldAnalysis.noteContentAnalysis.diversityScore))")
                print("    抽出数: \(testResult.fieldAnalysis.noteContentAnalysis.totalNoteExtractions)")
                if let mostCommon = testResult.fieldAnalysis.noteContentAnalysis.mostCommonNote {
                    print("    最頻出内容: \(mostCommon.prefix(50))...")
                }
            }
            
            // AI回答分析を表示
            print("  🤖 AI回答分析:")
            print("    \(testResult.fieldAnalysis.aiResponseAnalysis.analysisInsights.replacingOccurrences(of: "\n", with: "\n    "))")
            print(String(repeating: "-", count: 40))
        }

        // 統計情報を表示
        if let statistics = benchmark.statistics {
            print("\n📈 全体統計情報:")
            print("  総テスト数: \(statistics.totalTests)")
            print("  成功テスト数: \(statistics.successfulTests)")
            print("  成功率: \(String(format: "%.1f", statistics.successRate * 100))%")
            print("  平均抽出時間: \(String(format: "%.3f", statistics.averageExtractionTime))秒")
            print("  最短抽出時間: \(String(format: "%.3f", statistics.minExtractionTime))秒")
            print("  最長抽出時間: \(String(format: "%.3f", statistics.maxExtractionTime))秒")
            print("  平均メモリ使用量: \(String(format: "%.1f", statistics.averageMemoryUsage))MB")
            print("  平均信頼度: \(String(format: "%.2f", statistics.averageConfidence))")
            print("  平均抽出フィールド数: \(String(format: "%.1f", statistics.averageFieldCount))")
            
            // 警告分析
            if !statistics.warningCounts.isEmpty {
                print("\n⚠️ バリデーション警告分析:")
                for (warning, count) in statistics.warningCounts {
                    print("  \(warning): \(count)回")
                }
            }
        }

        // HTMLレポートを生成
        print("\n📊 HTMLレポートを生成中...")
        try HTMLReportGenerator.generateReport(
            results: benchmark.results,
            statistics: benchmark.statistics
        )

    } catch {
        print("❌ 繰り返しベンチマーク実行中にエラーが発生しました: \(error.localizedDescription)")
    }
}

/// テスト名を取得
func getTestName(testIndex: Int) -> String {
    let testNames = [
        "Chat Level 1 (Basic)",
        "Chat Level 2 (General)", 
        "Chat Level 3 (Complex)",
        "Contract Level 1 (Basic)",
        "Contract Level 2 (General)",
        "Contract Level 3 (Complex)",
        "Credit Card Level 1 (Basic)",
        "Credit Card Level 2 (General)",
        "Credit Card Level 3 (Complex)",
        "Voice Recognition Level 1 (Basic)",
        "Voice Recognition Level 2 (General)",
        "Voice Recognition Level 3 (Complex)",
        "Password Manager Level 1 (Basic)",
        "Password Manager Level 2 (General)",
        "Password Manager Level 3 (Complex)"
    ]
    
    return testNames.indices.contains(testIndex) ? testNames[testIndex] : "Test \(testIndex + 1)"
}

/// 単一テストデバッグ実行関数
@available(iOS 26.0, macOS 26.0, *)
@MainActor
func runSingleTestDebug() async {
    print("\n🔍 単一テストデバッグモード")
    print("📝 Chat/Level3_Complex.txt のAI回答を詳細分析")
    print(String(repeating: "=", count: 80))
    
    // テストデータを読み込み
    let testDataPath = "/Users/t.miyano/repos/AITest/Tests/TestData/Chat/Level3_Complex.txt"
    
    do {
        let testText = try String(contentsOfFile: testDataPath, encoding: .utf8)
        
        print("📝 テストデータ内容:")
        print(String(repeating: "-", count: 40))
        print(testText)
        print(String(repeating: "-", count: 40))
        
        print("\n🎯 単一テスト実行開始")
        print(String(repeating: "-", count: 60))
        
        let extractor = AccountExtractor()
        let (accountInfo, metrics) = try await extractor.extractFromText(testText)
        
        print("\n📊 AI抽出結果:")
        print(String(repeating: "-", count: 40))
        print("✅ 抽出成功!")
        print("📝 抽出されたAccountInfo:")
        print("  title: \(accountInfo.title ?? "nil")")
        print("  userID: \(accountInfo.userID ?? "nil")")
        print("  password: \(accountInfo.password ?? "nil")")
        print("  url: \(accountInfo.url ?? "nil")")
        print("  note: \(accountInfo.note ?? "nil")")
        print("  host: \(accountInfo.host ?? "nil")")
        print("  port: \(accountInfo.port?.description ?? "nil")")
        print("  authKey: \(accountInfo.authKey ?? "nil")")
        print("  confidence: \(accountInfo.confidence?.description ?? "nil")")
        
        print("\n📈 メトリクス:")
        print("  抽出時間: \(String(format: "%.3f", metrics.extractionTime))秒")
        print("  総処理時間: \(String(format: "%.3f", metrics.totalTime))秒")
        print("  メモリ使用量: \(String(format: "%.1f", metrics.memoryUsed))MB")
        print("  入力テキスト長: \(metrics.textLength) 文字")
        print("  抽出フィールド数: \(metrics.extractedFieldsCount)")
        print("  信頼度: \(String(format: "%.2f", metrics.confidence))")
        print("  有効性: \(metrics.isValid ? "✅" : "❌")")
        
        print("\n⚠️ バリデーション結果:")
        if metrics.validationResult.isValid {
            print("  ✅ 警告なし")
        } else {
            print("  ⚠️ 警告: \(metrics.validationResult.warnings.count)個")
            for warning in metrics.validationResult.warnings {
                print("    - \(warning.errorDescription ?? "不明な警告")")
            }
        }
        
        print("\n🔍 詳細分析:")
        print("  - 抽出されたフィールド数: \(accountInfo.extractedFieldsCount)")
        print("  - アカウントタイプ: \(accountInfo.accountType)")
        print("  - バリデーション有効性: \(accountInfo.isValid)")
        
    } catch {
        print("❌ ファイル読み込みエラー: \(error.localizedDescription)")
    }
}

/// 統計情報を計算
@available(iOS 26.0, macOS 26.0, *)
func calculateStatistics(from results: [AccountExtractionResult]) -> (totalTests: Int, successfulTests: Int, successRate: Double, averageExtractionTime: Double, averageMemoryUsage: Double, averageConfidence: Double) {
    let totalTests = results.count
    let successfulTests = results.filter { $0.success && $0.metrics != nil }.count
    let successRate = totalTests > 0 ? Double(successfulTests) / Double(totalTests) : 0.0
    
    let successfulResults = results.compactMap { $0.metrics }
    let averageExtractionTime = successfulResults.isEmpty ? 0.0 : successfulResults.map { $0.extractionTime }.reduce(0, +) / Double(successfulResults.count)
    let averageMemoryUsage = successfulResults.isEmpty ? 0.0 : successfulResults.map { $0.memoryUsed }.reduce(0, +) / Double(successfulResults.count)
    
    let confidences = results.compactMap { $0.accountInfo?.confidence }
    let averageConfidence = confidences.isEmpty ? 0.0 : confidences.reduce(0, +) / Double(confidences.count)
    
    return (totalTests, successfulTests, successRate, averageExtractionTime, averageMemoryUsage, averageConfidence)
}
