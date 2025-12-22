#!/usr/bin/env swift

import Foundation
import FoundationModels
import AITest

/// @ai[2025-01-18 08:00] メインアプリケーション用のログラッパー
/// 目的: メインアプリケーションのログ出力を統一
/// 背景: デバッグ時の可視性向上のため、すべてのログを統一された形式で出力
/// 意図: 開発効率の向上とデバッグの容易化
let log = LogWrapper(subsystem: "com.aitest.main", category: "MainApp")

/// @ai[2024-12-19 19:30] AITest コンソールアプリケーション
/// 目的: FoundationModelsを使用したAccount情報抽出の性能測定をコンソールで実行
/// 背景: macOSコンソールアプリとして実行可能なライブラリベースの実装
/// 意図: 真のAI機能を使用した性能評価をmacOSで実行

print("🚀 AITest コンソールアプリケーション開始")
print("OS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)")
print(String(repeating: "=", count: 80))

// @ai[2025-11-25 18:10] verboseモードの設定
// 目的: コマンドライン引数からverboseモードを判定し、LogWrapperのグローバルフラグを設定
// 背景: 詳細ログを条件付きで出力するため、アプリケーション起動時にverbose状態を設定
// 意図: すべてのLogWrapperインスタンスで一貫したverbose動作を実現
LogWrapper.isVerbose = extractVerboseFromArguments()
if LogWrapper.isVerbose {
    print("🔍 Verboseモード: 有効（詳細ログを表示します）")
}

// iOS 26+、macOS 26+の利用可能性チェック（メインターゲット）
if #available(iOS 26.0, macOS 26.0, *) {
    log.success("iOS 26+ / macOS 26+ の要件を満たしています")
    
    // FoundationModelsの利用可能性をチェック
    print("🔍 FoundationModelsの利用可能性をチェック中...")
    
    let systemModel = SystemLanguageModel.default
    let availability = systemModel.availability
    
    print("🔍 SystemLanguageModel.availability: \(String(describing: availability))")
    
    switch availability {
    case .available:
        log.success("AI利用可能 - ベンチマークを実行します")
        
        // タイムアウト設定（デフォルト: 300秒 = 5分）
        let timeoutSeconds = extractTimeoutFromArguments() ?? 300
        
        // デバッグモード: 単一テスト実行
        if CommandLine.arguments.contains("--debug-single") {
            // 実験設定を取得
            if let experiment = extractExperimentFromArguments() {
                // パターンを生成（最初のアルゴリズムを使用）
                let methodSuffix = experiment.method.rawValue == "generable" ? "gen" : experiment.method.rawValue
                let patternName = "\(experiment.algos.first ?? "strict")_\(methodSuffix)"
                let pattern = ExperimentPattern.allCases.first(where: { $0.rawValue == patternName }) ?? ExperimentPattern.absEx0S1Gen
                
                print("\n🔍 単一テストデバッグモード")
                print("📝 \(experiment.testcase)/Level3_Complex.txt のAI回答を詳細分析")
                print(String(repeating: "=", count: 80))
                
                await processExperiment(experiment: experiment, pattern: pattern, timeoutSeconds: timeoutSeconds)
            } else {
                print("❌ 実験設定が取得できませんでした")
                print("使用例: --debug-single --method json --testcase chat --language ja")
            }
        } else if CommandLine.arguments.contains("--debug-prompt") {
            await runPromptDebug()
        } else if CommandLine.arguments.contains("--collect-responses") {
            await runResponseCollection()
        } else if CommandLine.arguments.contains("--test-extraction-methods") || CommandLine.arguments.contains("--experiment") || 
                  CommandLine.arguments.contains("--method") || CommandLine.arguments.contains("--language") || CommandLine.arguments.contains("--testcase") || CommandLine.arguments.contains("--testcases") || CommandLine.arguments.contains("--algos") || CommandLine.arguments.contains("--levels") {
        // 特定のexperimentを実行するかチェック
        print("🔍 コマンドライン引数をチェック中...")
        print("   引数: \(CommandLine.arguments)")
        
        if let experiment = extractExperimentFromArguments() {
            log.success("特定のexperimentを検出: \(experiment.method.rawValue)_\(experiment.language.rawValue)_\(experiment.testcase)_\(experiment.algos.joined(separator: ","))")
            
            // 複数のアルゴリズムを処理
            await processExperiment(experiment: experiment, pattern: ExperimentPattern.absEx0S1Gen, timeoutSeconds: timeoutSeconds)
        } else {
                print("⚠️ 特定のexperimentが指定されていません - デフォルトでgenerable_jaを実行")
                // @ai[2025-11-07 04:13] デフォルトをgenerable_jaに変更（yamlは削除されたため）
                // 目的: yaml削除に伴うデフォルト値の更新
                // 背景: yamlはサポートされなくなったため、generableをデフォルトに設定
                // 意図: 既存の動作を維持しつつ、サポートされている方法を使用
                let defaultExperiment = (method: ExtractionMethod.generable, language: PromptLanguage.japanese, testcase: "chat", algos: ["abs"], mode: ExtractionMode.simple, levels: [1, 2, 3])
                _ = extractTestDirFromArguments()
                await processExperiment(experiment: defaultExperiment, pattern: ExperimentPattern.defaultPattern, timeoutSeconds: timeoutSeconds)
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
                    // 新しい統一抽出フローを使用
                    let factory = ExtractorFactory()
                    let modelExtractor = factory.createExtractor(externalLLMConfig: nil as LLMConfig?)
                    let unifiedExtractor = UnifiedExtractor(modelExtractor: modelExtractor)
                    
                    // テストケース名からレベルを抽出
                    let (pattern, level) = parseTestCaseName(testCase.name)
                    let (accountInfo, metrics, _, _, _) = try await unifiedExtractor.extract(
                        testcase: pattern,
                        level: level,
                        method: method,
                        algo: "abs", // デフォルト値
                        language: language,
                        useTwoSteps: ExtractionMode.simple.useTwoSteps // デフォルトは単純推定
                    )
                    
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
                    """
                    
                    reportData.append((
                        testCase: testCase.name,
                        method: "\(method.rawValue) (\(language.rawValue))",
                        language: language.displayName,
                        result: result,
                        metrics: metricsStr
                    ))
                    
                } catch {
                    let errorResult = "エラー: \(error.localizedDescription)"
                    let errorMetrics = "抽出失敗"
                    
                    reportData.append((
                        testCase: testCase.name,
                        method: "\(method.rawValue) (\(language.rawValue))",
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

/// コマンドライン引数から外部LLM設定を抽出
@available(iOS 26.0, macOS 26.0, *)
func extractExternalLLMConfigFromArguments() -> LLMConfig? {
    var baseURL: String?
    var model: String?
    
    let arguments = CommandLine.arguments
    print("🔍 外部LLM設定解析開始 - 引数数: \(arguments.count)")
    
    for i in 0..<arguments.count {
        let argument = arguments[i]
        print("🔍 引数[\(i)]: \(argument)")
        
        if argument.hasPrefix("--external-llm-url=") {
            baseURL = String(argument.dropFirst("--external-llm-url=".count))
            print("✅ URL設定: \(baseURL ?? "nil")")
        } else if argument.hasPrefix("--external-llm-model=") {
            model = String(argument.dropFirst("--external-llm-model=".count))
            print("✅ モデル設定: \(model ?? "nil")")
        } else if argument == "--external-llm-url" && i + 1 < arguments.count {
            baseURL = arguments[i + 1]
            print("✅ URL設定(分離): \(baseURL ?? "nil")")
        } else if argument == "--external-llm-model" && i + 1 < arguments.count {
            model = arguments[i + 1]
            print("✅ モデル設定(分離): \(model ?? "nil")")
        }
    }
    
    print("🔍 最終結果 - URL: \(baseURL ?? "nil"), モデル: \(model ?? "nil")")
    
    guard let baseURL = baseURL, let model = model else {
        print("❌ 外部LLM設定が不完全です")
        return nil
    }
    
    return LLMConfig(
        baseURL: baseURL,
        apiKey: "dummy-key", // 外部LLMテスト用のダミーキー
        model: model
    )
}

/// コマンドライン引数のバリデーション
@available(iOS 26.0, macOS 26.0, *)
func validateArguments() -> (isValid: Bool, errors: [String]) {
    var errors: [String] = []
    let validOptions = ["--method", "--language", "--testcase", "--testcases", "--algo", "--algos", "--levels", "--runs", "--mode", "--external-llm-url", "--external-llm-model", "--timeout", "--debug-single", "--debug-prompt", "--collect-responses", "--test-extraction-methods", "--experiment", "--test-dir", "--verbose", "-v"]
    
    // サポートされているオプションをチェック
    for argument in CommandLine.arguments {
        if argument.hasPrefix("--") {
            let option = argument.split(separator: "=").first.map(String.init) ?? argument
            if !validOptions.contains(option) {
                errors.append("❌ サポートされていないオプション: \(option)")
            }
        }
    }
    
    // 必須引数の組み合わせチェック
    let hasMethod = CommandLine.arguments.contains { $0.hasPrefix("--method") }
    let _ = CommandLine.arguments.contains { $0.hasPrefix("--language") }
    let hasTestcase = CommandLine.arguments.contains { $0.hasPrefix("--testcase") }
    let hasTestcases = CommandLine.arguments.contains { $0.hasPrefix("--testcases") }
    let hasAlgos = CommandLine.arguments.contains { $0.hasPrefix("--algos") }
    let hasLevels = CommandLine.arguments.contains { $0.hasPrefix("--levels") }
    
    // 実験実行の場合は最低限の引数が必要
    if CommandLine.arguments.contains("--experiment") || hasMethod || hasTestcase || hasTestcases || hasAlgos || hasLevels {
        if !hasMethod && !hasTestcase && !hasTestcases && !hasAlgos && !hasLevels {
            errors.append("❌ 実験実行には最低限 --method または --testcase の指定が必要です")
        }
    }
    
    return (errors.isEmpty, errors)
}

/// ヘルプメッセージを表示
@available(iOS 26.0, macOS 26.0, *)
func printHelp() {
    print("\n📖 AITestApp 使用方法:")
    print(String(repeating: "=", count: 60))
    print("基本的な使用方法:")
    print("  swift run AITestApp --method <method> --testcase <testcase> --language <language>")
    print()
    print("引数:")
    print("  --method <method>     抽出方法 (json, generable) [デフォルト: generable]")
    print("  --testcase <testcase> 指示タイプ (abs, strict, persona, abs-ex, strict-ex, persona-ex) [デフォルト: strict]")
    print("  --language <language> 言語 (ja, en) [デフォルト: ja]")
    print("  --mode <mode>         抽出モード (simple, two-steps) [デフォルト: simple]")
    print("  --levels <levels>     テストレベル (例: 1,2) [デフォルト: 1,2,3]")
    print("  --runs <number>       実行回数 [デフォルト: 1]")
    print("  --timeout <seconds>   タイムアウト秒数 [デフォルト: 300]")
    print()
    print("デバッグオプション:")
    print("  --debug-single        単一テストデバッグ実行")
    print("  --debug-prompt        プロンプト確認（--method, --testcase, --language と組み合わせ）")
    print("  --collect-responses   AIレスポンス収集（chat_abs_json_jaのlevel1-3を各10回実行）")
    print()
    print("外部LLMオプション:")
    print("  --external-llm-url <url>     外部LLMのベースURL")
    print("  --external-llm-model <model> 外部LLMのモデル名")
    print()
    print("使用例:")
    print("  swift run AITestApp --method json --testcase strict --language ja")
    print("  swift run AITestApp --method generable --testcase chat --language ja --mode two-steps")
    print("  swift run AITestApp --method generable --testcase chat --language ja --levels 1")
    print("  swift run AITestApp --debug-prompt --method json --testcase strict --language ja")
    print("  swift run AITestApp --method generable --testcase abs --runs 5")
    print(String(repeating: "=", count: 60))
}

/// コマンドライン引数からexperimentを抽出（新しい統一引数方式）
@available(iOS 26.0, macOS 26.0, *)
func extractExperimentFromArguments() -> (method: ExtractionMethod, language: PromptLanguage, testcase: String, algos: [String], mode: ExtractionMode, levels: [Int])? {
    print("🔍 extractExperimentFromArguments 開始")

    // 引数バリデーション
    let validation = validateArguments()
    if !validation.isValid {
        print("❌ 引数エラー:")
        for error in validation.errors {
            print("   \(error)")
        }
        printHelp()
        return nil
    }

    print("   利用可能なExtractionMethod: \(ExtractionMethod.allCases.map { $0.rawValue })")
    print("   利用可能なPromptLanguage: \(PromptLanguage.allCases.map { $0.rawValue })")
    print("   利用可能なExtractionMode: \(ExtractionMode.allCases.map { $0.rawValue })")
    print("   利用可能なTestcase: chat, creditcard, contract, password, voice")
    print("   利用可能なAlgo: abs, strict, persona, abs-ex, strict-ex, persona-ex")

    var method: ExtractionMethod = .generable  // デフォルト
    var language: PromptLanguage = .japanese   // デフォルト
    var testcase: String = "chat"              // デフォルト
    var algos: [String] = ["strict"]           // デフォルト
    var mode: ExtractionMode = .simple         // デフォルト
    var levels: [Int] = [1, 2, 3]              // デフォルト（全レベル）
    
    // 有効なtestcase値の定義
    let validTestcases = ["chat", "creditcard", "contract", "password", "voice"]
    let validAlgos = ["abs", "strict", "persona", "abs-ex", "strict-ex", "persona-ex"]
    
    // @ai[2025-11-07 04:16] オプション抽出ロジックの統合
    // 目的: --option=形式を削除し、--option形式のみをサポート
    // 背景: 冗長なコードを統合して保守性を向上
    // 意図: コードの重複を排除し、可読性と保守性を向上
    
    // --method の形式をチェック（次の引数を取得）
    for (index, argument) in CommandLine.arguments.enumerated() {
        if argument == "--method" && index + 1 < CommandLine.arguments.count {
            let methodString = CommandLine.arguments[index + 1]
            print("   --method 形式を検出: \(methodString)")
            
            if let extractedMethod = ExtractionMethod.allCases.first(where: { $0.rawValue == methodString }) {
                method = extractedMethod
                print("✅ methodを抽出: \(method.rawValue)")
            } else {
                print("❌ 無効なmethod指定: \(methodString)")
                print("   有効な値: \(ExtractionMethod.allCases.map { $0.rawValue }.joined(separator: ", "))")
                return nil
            }
        }
    }
    
    // --testcase の形式をチェック（次の引数を取得）
    for (index, argument) in CommandLine.arguments.enumerated() {
        if argument == "--testcase" && index + 1 < CommandLine.arguments.count {
            let testcaseString = CommandLine.arguments[index + 1]
            print("   --testcase 形式を検出: \(testcaseString)")
            
            if validTestcases.contains(testcaseString) {
                testcase = testcaseString
                print("✅ testcaseを抽出: \(testcase)")
            } else {
                print("❌ 無効なtestcase指定: \(testcaseString)")
                print("   有効な値: \(validTestcases.joined(separator: ", "))")
                return nil
            }
        }
    }
    
    // --algo の形式をチェック（次の引数を取得）
    for (index, argument) in CommandLine.arguments.enumerated() {
        if argument == "--algo" && index + 1 < CommandLine.arguments.count {
            let algoString = CommandLine.arguments[index + 1]
            print("   --algo 形式を検出: \(algoString)")
            
            if validAlgos.contains(algoString) {
                algos = [algoString]
                print("✅ algoを抽出: \(algos.joined(separator: ", "))")
            } else {
                print("❌ 無効なalgo指定: \(algoString)")
                print("   有効な値: \(validAlgos.joined(separator: ", "))")
                return nil
            }
        }
    }
    
    // --algos の形式をチェック（次の引数を取得）
    if let index = CommandLine.arguments.firstIndex(of: "--algos") {
        var extractedAlgos: [String] = []
        var i = index + 1
        while i < CommandLine.arguments.count && !CommandLine.arguments[i].hasPrefix("--") {
            extractedAlgos.append(CommandLine.arguments[i])
            i += 1
        }
        
        if !extractedAlgos.isEmpty {
            print("   --algos 形式を検出: \(extractedAlgos.joined(separator: ", "))")
            
            // 有効なアルゴリズムのみをフィルタリング
            let validExtractedAlgos = extractedAlgos.filter { validAlgos.contains($0) }
            if !validExtractedAlgos.isEmpty {
                algos = validExtractedAlgos
                print("✅ algosを抽出: \(algos.joined(separator: ", "))")
            } else {
                print("❌ 有効なalgoが指定されていません")
                print("   有効な値: \(validAlgos.joined(separator: ", "))")
                return nil
            }
        }
    }
    
    // --language の形式をチェック（次の引数を取得）
    for (index, argument) in CommandLine.arguments.enumerated() {
        if argument == "--language" && index + 1 < CommandLine.arguments.count {
            let languageString = CommandLine.arguments[index + 1]
            print("   --language 形式を検出: \(languageString)")

            if let extractedLanguage = PromptLanguage.allCases.first(where: { $0.rawValue == languageString }) {
                language = extractedLanguage
                print("✅ languageを抽出: \(language.rawValue)")
            } else {
                print("❌ 無効なlanguage指定: \(languageString)")
                print("   有効な値: \(PromptLanguage.allCases.map { $0.rawValue }.joined(separator: ", "))")
                return nil
            }
        }
    }

    // --mode の形式をチェック（次の引数を取得）
    for (index, argument) in CommandLine.arguments.enumerated() {
        if argument == "--mode" && index + 1 < CommandLine.arguments.count {
            let modeString = CommandLine.arguments[index + 1]
            print("   --mode 形式を検出: \(modeString)")

            if let extractedMode = ExtractionMode.allCases.first(where: { $0.rawValue == modeString }) {
                mode = extractedMode
                print("✅ modeを抽出: \(mode.rawValue)")
            } else {
                print("❌ 無効なmode指定: \(modeString)")
                print("   有効な値: \(ExtractionMode.allCases.map { $0.rawValue }.joined(separator: ", "))")
                return nil
            }
        }
    }

    // --levels の形式をチェック（次の引数を取得）
    for (index, argument) in CommandLine.arguments.enumerated() {
        if argument == "--levels" && index + 1 < CommandLine.arguments.count {
            let levelsString = CommandLine.arguments[index + 1]
            print("   --levels 形式を検出: \(levelsString)")

            let levelStrings = levelsString.split(separator: ",").map(String.init)
            let extractedLevels = levelStrings.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

            if !extractedLevels.isEmpty {
                levels = extractedLevels
                print("✅ levelsを抽出: \(levels.map(String.init).joined(separator: ", "))")
            } else {
                print("❌ 無効なlevels指定: \(levelsString)")
                return nil
            }
        }
    }

    // 最終結果を表示
    print("✅ 最終結果: method=\(method.rawValue), language=\(language.rawValue), testcase=\(testcase), algos=\(algos.joined(separator: ", ")), mode=\(mode.rawValue), levels=\(levels.map(String.init).joined(separator: ", "))")

    return (method: method, language: language, testcase: testcase, algos: algos, mode: mode, levels: levels)
}

/// 実験処理を実行
@available(iOS 26.0, macOS 26.0, *)
func processExperiment(experiment: (method: ExtractionMethod, language: PromptLanguage, testcase: String, algos: [String], mode: ExtractionMode, levels: [Int]), pattern: ExperimentPattern, timeoutSeconds: Int) async {
    // 外部LLM設定の取得
    let externalLLMConfig = extractExternalLLMConfigFromArguments()
    if let config = externalLLMConfig {
        print("🌐 外部LLM設定を検出: \(config.baseURL) (モデル: \(config.model))")
        
        // @ai[2025-01-18 07:00] 外部LLM設定のassertion
        assert(!config.baseURL.isEmpty, "外部LLMのbaseURLが空です")
        assert(!config.model.isEmpty, "外部LLMのmodelが空です")
        print("✅ 外部LLM設定のassertion通過")
    } else {
        print("⚠️ 外部LLM設定が見つかりませんでした")
    }
    
    // テストディレクトリの取得と統一
    let testDir = extractTestDirFromArguments()
    let finalTestDir: String
    if let providedTestDir = testDir {
        // @ai[2025-01-19 16:30] --test-dirが指定された場合はそのまま使用
        finalTestDir = providedTestDir
    } else {
        // @ai[2025-01-19 16:30] 統一されたディレクトリ名を生成
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        let timestamp = formatter.string(from: Date())
        let experimentName = "\(experiment.method.rawValue)_\(experiment.language.rawValue)"
        finalTestDir = "test_logs/\(timestamp)_\(experimentName)"
    }
    
    // 統一されたディレクトリを作成
    print("🔍 統一ディレクトリ作成開始 - パス: \(finalTestDir)")
    createLogDirectory(finalTestDir)
    print("🔍 統一ディレクトリ作成完了")
    
    // 外部LLM設定をコピーしてSendableにする
    let configCopy: LLMConfig? = externalLLMConfig.map { config in
        LLMConfig(
            baseURL: config.baseURL,
            apiKey: config.apiKey,
            model: config.model
        )
    }
    
    // 各アルゴリズムに対して実験を実行
    for algo in experiment.algos {
        print("\n🔬 アルゴリズム '\(algo)' の実験を開始")
        
        // パターンを生成（algo + method、testcaseは無視）
        let methodSuffix = experiment.method.rawValue == "generable" ? "gen" : experiment.method.rawValue
        let patternName = "\(algo)_\(methodSuffix)"
        if let pattern = ExperimentPattern.allCases.first(where: { $0.rawValue == patternName }) {
            // パターンが見つかった場合の処理
            let singleExperiment = (method: experiment.method, language: experiment.language, testcase: experiment.testcase, algo: algo, mode: experiment.mode, levels: experiment.levels)
            await runSpecificExperiment(singleExperiment, pattern: pattern, testDir: finalTestDir, externalLLMConfig: configCopy)
        } else {
            print("❌ 無効なパターン組み合わせ: \(patternName)")
            print("   有効な組み合わせ: testcase + algo + method")
            print("   スキップします")
        }
    }
}

/// パターン名を実際のテストデータディレクトリ名にマッピング
func mapPatternToTestDataDirectory(_ pattern: String) -> String {
    // 実験パターンは全て同じテストデータを使用（Chat、Contract、CreditCard、VoiceRecognition、PasswordManager）
    // デフォルトでChatパターンを使用
    return "Chat"
}

/// コマンドライン引数から実行回数を抽出
func extractRunsFromArguments() -> Int? {
    let arguments = CommandLine.arguments
    
    // 形式1: --runs=3 をチェック
    for argument in arguments {
        if argument.hasPrefix("--runs=") {
            let value = String(argument.dropFirst(7))
            if let runs = Int(value) {
                return runs
            }
        }
    }
    
    // 形式2: --runs 3 をチェック
    if let index = arguments.firstIndex(of: "--runs") {
        if index + 1 < arguments.count {
            if let runs = Int(arguments[index + 1]) {
                return runs
            }
        }
    }
    
    return nil
}

/// コマンドライン引数からテストディレクトリを抽出
func extractTestDirFromArguments() -> String? {
    let arguments = CommandLine.arguments
    
    // 形式1: --test-dir=path をチェック
    for argument in arguments {
        if argument.hasPrefix("--test-dir=") {
            return String(argument.dropFirst("--test-dir=".count))
        }
    }
    
    // 形式2: --test-dir path をチェック
    for (index, argument) in arguments.enumerated() {
        if argument == "--test-dir" && index + 1 < arguments.count {
            return arguments[index + 1]
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
        // すべてのタスクをキャンセル
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
func runSpecificExperiment(_ experiment: (method: ExtractionMethod, language: PromptLanguage, testcase: String, algo: String, mode: ExtractionMode, levels: [Int]), pattern: ExperimentPattern, testDir: String?, runNumber: Int = 1, externalLLMConfig: LLMConfig? = nil) async {
    let timer = PerformanceTimer("特定実験全体")
    timer.start()
    
    // --runs引数から実行回数を取得
    let runs = extractRunsFromArguments() ?? 1
    
    print("\n🔬 特定実験を開始: \(experiment.method.rawValue) (\(experiment.language.rawValue))")
    print("📋 パターン指定: \(pattern.displayName)")
    print("🔄 実行回数: \(runs)回")
    print("🔄 指定された抽出方法・言語・パターンのみを実行します")
    print(String(repeating: "-", count: 60))
    
    // テスト実行用のディレクトリを決定（新しい命名規則: yyyymmddhhmm_実験名）
    let finalTestDir: String
    if let providedTestDir = testDir {
        // @ai[2025-01-10 15:45] --test-dirが指定された場合はそのまま使用
        finalTestDir = providedTestDir
    } else {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        let timestamp = formatter.string(from: Date())
        let experimentName = "\(experiment.method.rawValue)_\(experiment.language.rawValue)"
        finalTestDir = "test_logs/\(timestamp)_\(experimentName)"
    }
    if LogWrapper.isVerbose {
        print("🔍 DEBUG: ディレクトリ作成開始 - パス: \(finalTestDir)")
    }
    createLogDirectory(finalTestDir)
    if LogWrapper.isVerbose {
        print("🔍 DEBUG: ディレクトリ作成完了")
    }
    timer.checkpoint("ディレクトリ作成完了")
    
    // テストケースの読み込み
    // experiment.testcaseを使用（mapPatternToTestDataDirectoryは廃止）
    if LogWrapper.isVerbose {
        print("🔍 DEBUG: パターンマッピング: \(pattern.rawValue) -> \(experiment.testcase)")
    }
    let allTestCases = loadTestCases(pattern: experiment.testcase)

    // levelsでテストケースをフィルタリング
    let testCases = allTestCases.filter { testCase in
        let (_, level) = parseTestCaseName(testCase.name)
        return experiment.levels.contains(level)
    }
    if LogWrapper.isVerbose {
        print("🔍 DEBUG: 全テストケース数: \(allTestCases.count), フィルタ後: \(testCases.count), 対象レベル: \(experiment.levels.map(String.init).joined(separator: ", "))")
    }
    timer.checkpoint("テストケース読み込み完了")

    // 各テストケースに対して指定回数実行
    for (index, testCase) in testCases.enumerated() {
        let (testPattern, level) = parseTestCaseName(testCase.name)
        
        print("\n📋 テストケース \(index + 1)/\(testCases.count): \(testCase.name)")
        print("📝 入力テキスト: \(testCase.text.prefix(100))...")
        print("🔄 実行回数: \(runs)回")
        print(String(repeating: "-", count: 60))
        
        // デバッグ: 期待値の取得をテスト
        print("🔍 期待値取得テスト:")
        let expectedFields = getExpectedFields(for: testPattern, level: level)
        for field in expectedFields {
            let expectedValue = getExpectedValue(for: field, testCaseName: testCase.name)
            print("  \(field): '\(expectedValue)'")
        }
        
        print("\n🔍 抽出方法: \(experiment.method.rawValue) (\(experiment.language.rawValue))")
        print("📝 説明: \(experiment.method.rawValue) - \(experiment.language.rawValue)")
        
        // 指定回数実行
        for run in 1...runs {
            let testTimer = PerformanceTimer("テストケース\(index + 1)_実行\(run)")
            testTimer.start()
            
            print("\n🔄 実行 \(run)/\(runs)")
            print(String(repeating: "-", count: 40))
        
        do {
            // 新しい統一抽出フローを使用
            let factory = ExtractorFactory()
            let modelExtractor = factory.createExtractor(externalLLMConfig: externalLLMConfig)
            let unifiedExtractor = UnifiedExtractor(modelExtractor: modelExtractor)
            testTimer.checkpoint("抽出器作成完了")
            
            if LogWrapper.isVerbose {
                print("🔍 DEBUG: 統一抽出フロー開始")
                print("🔍 DEBUG: 外部LLM設定: \(externalLLMConfig != nil ? "設定あり" : "設定なし")")
                if let config = externalLLMConfig {
                    print("🔍 DEBUG: 外部LLM設定詳細: URL=\(config.baseURL), モデル=\(config.model)")
                }
            }
            
            // テストケース名からレベルを抽出
            let (testPattern, level) = parseTestCaseName(testCase.name)
            let (accountInfo, metrics, _, requestContent, contentInfo) = try await unifiedExtractor.extract(
                testcase: testPattern,
                level: level,
                method: experiment.method,
                algo: "abs", // デフォルト値
                language: experiment.language,
                useTwoSteps: experiment.mode.useTwoSteps
            )
            testTimer.checkpoint("AI抽出完了")

            print("✅ 抽出成功")
            print("  ⏱️  抽出時間: \(String(format: "%.3f", metrics.extractionTime))秒")
            print("  ⏱️  総時間: \(String(format: "%.3f", metrics.totalTime))秒")
            print("  📊 抽出フィールド数: \(accountInfo.extractedFieldsCount)")

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
            if LogWrapper.isVerbose {
                print("🔍 DEBUG: generateStructuredLog呼び出し開始")
            }
            await generateStructuredLog(testCase: testCase, accountInfo: accountInfo, experiment: experiment, pattern: pattern, iteration: 1, runNumber: run, testDir: finalTestDir, requestContent: requestContent, contentInfo: contentInfo)
            if LogWrapper.isVerbose {
                print("🔍 DEBUG: generateStructuredLog呼び出し完了")
            }
            testTimer.checkpoint("ログ出力完了")
            
        } catch {
            print("❌ 抽出失敗: \(error.localizedDescription)")
            if LogWrapper.isVerbose {
                print("🔍 DEBUG: エラーの詳細: \(error)")
            }
            
            // エラー時の構造化ログ
            await generateErrorStructuredLog(testCase: testCase, error: error, experiment: experiment, pattern: pattern, iteration: 1, runNumber: run, testDir: finalTestDir, requestContent: nil)
            testTimer.checkpoint("エラーログ出力完了")
        }
        
        testTimer.end()
        print(String(repeating: "=", count: 60))
        }
    }
    
    // HTMLレポートの生成
    await generateFormatExperimentReport(testDir: finalTestDir, experiment: experiment, pattern: pattern, testCases: testCases)
    timer.checkpoint("HTMLレポート生成完了")
    
    timer.end()
    print("\n📊 特定実験完了")
    print("📁 テスト結果: \(finalTestDir)/")
}

/// フォーマット実験レポートを生成
@available(iOS 26.0, macOS 26.0, *)
func generateFormatExperimentReport(testDir: String, experiment: (method: ExtractionMethod, language: PromptLanguage, testcase: String, algo: String, mode: ExtractionMode, levels: [Int]), pattern: ExperimentPattern, testCases: [(name: String, text: String)]) async {
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
            <p>抽出方法: \(experiment.method.rawValue)</p>
            <p>言語: \(experiment.language.displayName)</p>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>テストケース数</h3>
                <p style="font-size: 2em; margin: 0;">\(testCases.count)</p>
            </div>
            <div class="summary-card">
                <h3>抽出方法</h3>
                <p style="font-size: 1.5em; margin: 0;">\(experiment.method.rawValue)</p>
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
        try htmlContent.write(toFile: htmlFilePath, atomically: true, encoding: String.Encoding.utf8)
        print("📄 HTMLレポート生成: \(htmlFilePath)")
    } catch {
        print("❌ HTMLレポート生成エラー: \(error.localizedDescription)")
    }
}

/// ログディレクトリを作成
/// @ai[2025-11-25 18:10] verboseモード対応を追加
/// 目的: DEBUG出力をverboseモード時のみ表示
/// 背景: 冗長なDEBUG出力が通常実行時のログを読みにくくしている
/// 意図: verboseモード時のみ詳細ログを表示
func createLogDirectory(_ path: String) {
    if LogWrapper.isVerbose {
        print("🔍 DEBUG: createLogDirectory開始 - パス: \(path)")
    }
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: path) {
        if LogWrapper.isVerbose {
            print("🔍 DEBUG: ディレクトリが存在しないため作成します")
        }
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            if LogWrapper.isVerbose {
                print("🔍 DEBUG: ディレクトリ作成成功")
            }
        } catch {
            print("❌ DEBUG: ディレクトリ作成失敗: \(error.localizedDescription)")
        }
    } else {
        if LogWrapper.isVerbose {
            print("🔍 DEBUG: ディレクトリは既に存在します")
        }
    }
    if LogWrapper.isVerbose {
        print("🔍 DEBUG: createLogDirectory完了")
    }
}

/// 構造化ログを生成
/// @ai[2025-10-22 18:25] 2ステップ方式のカテゴリ結果を追加
/// @ai[2025-11-25 18:10] verboseモード対応を追加
/// 目的: DEBUG出力をverboseモード時のみ表示
/// 背景: 冗長なDEBUG出力が通常実行時のログを読みにくくしている
/// 意図: verboseモード時のみ詳細ログを表示
@available(iOS 26.0, macOS 26.0, *)
func generateStructuredLog(testCase: (name: String, text: String), accountInfo: AccountInfo, experiment: (method: ExtractionMethod, language: PromptLanguage, testcase: String, algo: String, mode: ExtractionMode, levels: [Int]), pattern: ExperimentPattern, iteration: Int, runNumber: Int, testDir: String, requestContent: String?, contentInfo: ContentInfo?) async {
    if LogWrapper.isVerbose {
        print("🔍 DEBUG: generateStructuredLog開始 - testDir: \(testDir)")
    }
    let (testPattern, level) = parseTestCaseName(testCase.name)
    if LogWrapper.isVerbose {
        print("🔍 DEBUG: パターン: \(testPattern), レベル: \(level)")
    }
    let expectedFields = getExpectedFields(for: testPattern, level: level)
    if LogWrapper.isVerbose {
        print("🔍 DEBUG: 期待フィールド数: \(expectedFields.count)")
    }

    var structuredLog: [String: Any] = [
        "pattern": testPattern,
        "level": level,
        "iteration": iteration,
        "method": experiment.method.rawValue,
        "language": experiment.language.rawValue,
        "experiment_pattern": pattern.rawValue,
        "request_content": requestContent ?? NSNull(),
        "expected_fields": [],
        "unexpected_fields": []
    ]

    // 2ステップ方式の場合、メインカテゴリとサブカテゴリの結果を追加
    if experiment.mode == .twoSteps, let contentInfo = contentInfo {
        // カテゴリ表示名をCategoryDefinitionLoaderから取得
        let loader = CategoryDefinitionLoader()
        var mainCategoryDisplay: String
        var subCategoryDisplay: String

        do {
            let categoryDef = try loader.loadCategoryDefinition()
            mainCategoryDisplay = categoryDef.mainCategories.first(where: { $0.id == contentInfo.mainCategory })?.name.ja ?? contentInfo.mainCategory

            let subCategoryDef = try loader.loadSubCategoryDefinition(subCategoryId: contentInfo.subCategory)
            subCategoryDisplay = subCategoryDef.name.ja
        } catch {
            mainCategoryDisplay = contentInfo.mainCategory
            subCategoryDisplay = contentInfo.subCategory
        }

        // @ai[2025-12-11 17:50] カテゴリ判定の検証を追加
        // @ai[2025-12-11 18:00] expectedCategoryを必須に変更
        // 目的: 期待カテゴリと抽出カテゴリを比較して精度を評価
        // 背景: テストケースファイルのヘッダで期待カテゴリを宣言（必須）
        // 意図: カテゴリ判定の正しさを客観的に評価する。期待カテゴリが指定されていない場合はgetExpectedCategoryでfatalErrorが発生する
        let (pattern, level) = parseTestCaseName(testCase.name)
        let expectedCategory = getExpectedCategory(for: pattern, level: level)
        
        let mainCategoryCorrect = contentInfo.mainCategory == expectedCategory.mainCategory
        let subCategoryCorrect = contentInfo.subCategory == expectedCategory.subCategory
        let categoryCorrect = mainCategoryCorrect && subCategoryCorrect
        
        let categoryStatus: [String: Any] = [
            "main_category": contentInfo.mainCategory,
            "main_category_display": mainCategoryDisplay,
            "sub_category": contentInfo.subCategory,
            "sub_category_display": subCategoryDisplay,
            "expected_main_category": expectedCategory.mainCategory,
            "expected_sub_category": expectedCategory.subCategory,
            "main_category_status": mainCategoryCorrect ? "correct" : "wrong",
            "sub_category_status": subCategoryCorrect ? "correct" : "wrong",
            "category_status": categoryCorrect ? "correct" : "wrong"
        ]
        
        structuredLog["two_steps_category"] = categoryStatus
    }
    
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
            let logFileName = "\(experiment.testcase)_\(experiment.algo)_\(experiment.method.rawValue)_\(experiment.language.rawValue)_level\(level)_run\(runNumber).json"
            let logFilePath = "\(testDir)/\(logFileName)"
            if LogWrapper.isVerbose {
                print("🔍 DEBUG: ログファイル保存開始 - パス: \(logFilePath)")
            }
            try jsonString.write(toFile: logFilePath, atomically: true, encoding: .utf8)
            print("💾 ログ保存: \(logFilePath)")
            if LogWrapper.isVerbose {
                print("🔍 DEBUG: ログファイル保存完了")
            }
        }
    } catch {
        print("❌ 構造化ログ生成エラー: \(error.localizedDescription)")
    }
}

/// エラー時の構造化ログを生成
/// @ai[2025-10-24 12:00] エラー詳細のデバッグ出力を追加
/// 目的: エラー原因の分析を容易にする
/// 背景: _error.jsonが作成される原因を調査できるようにする
/// 意図: エラーの型、詳細、コンテキスト情報を出力
@available(iOS 26.0, macOS 26.0, *)
func generateErrorStructuredLog(testCase: (name: String, text: String), error: Error, experiment: (method: ExtractionMethod, language: PromptLanguage, testcase: String, algo: String, mode: ExtractionMode, levels: [Int]), pattern: ExperimentPattern, iteration: Int, runNumber: Int, testDir: String, requestContent: String?) async {
    let (testPattern, level) = parseTestCaseName(testCase.name)
    let expectedFields = getExpectedFields(for: testPattern, level: level)

    // エラー詳細情報のデバッグ出力
    print("\n" + String(repeating: "!", count: 80))
    print("🐛 ERROR DIAGNOSTICS - 詳細エラー情報")
    print(String(repeating: "!", count: 80))
    print("📌 実験情報:")
    print("   - パターン: \(testPattern)")
    print("   - レベル: \(level)")
    print("   - 実行番号: \(runNumber)")
    print("   - 抽出方法: \(experiment.method.rawValue)")
    print("   - 言語: \(experiment.language.rawValue)")
    print("   - モード: \(experiment.mode)")
    print("   - テストケース: \(testCase.name)")
    print("\n📌 エラー情報:")
    print("   - エラー型: \(type(of: error))")
    print("   - エラーメッセージ: \(error.localizedDescription)")

    // ExtractionError の場合は詳細情報を出力
    if let extractionError = error as? ExtractionError {
        print("   - ExtractionErrorの種類:")
        switch extractionError {
        case .invalidInput:
            print("     → invalidInput: 無効な入力データ（Two-Stepsでサブカテゴリ判定失敗の可能性）")
        case .noAccountInfoFound:
            print("     → noAccountInfoFound: アカウント情報が見つからない")
        case .languageModelUnavailable:
            print("     → languageModelUnavailable: 言語モデルが利用できない")
        case .appleIntelligenceDisabled:
            print("     → appleIntelligenceDisabled: Apple Intelligenceが無効")
        case .deviceNotEligible:
            print("     → deviceNotEligible: デバイスが対応していない")
        case .modelNotReady:
            print("     → modelNotReady: モデルをダウンロード中")
        case .aifmNotSupported:
            print("     → aifmNotSupported: FoundationModelsがサポートされていない")
        case .invalidJSONFormat(let response):
            print("     → invalidJSONFormat: 無効なJSON形式")
            if let response = response {
                print("     → AIレスポンス（最初の200文字）: \(String(response.prefix(200)))")
            }
        case .externalLLMError(let response):
            print("     → externalLLMError: 外部LLMエラー")
            print("     → AIレスポンス（最初の200文字）: \(String(response.prefix(200)))")
        case .testDataNotFound(let message):
            print("     → testDataNotFound: \(message)")
        case .invalidImageData:
            print("     → invalidImageData: 無効な画像データ")
        case .promptTemplateNotFound(let templateName):
            print("     → promptTemplateNotFound: プロンプトテンプレートが見つからない (\(templateName))")
        case .mappingRuleNotFound(let ruleName):
            print("     → mappingRuleNotFound: マッピングルールが見つからない (\(ruleName))")
        case .methodNotSupported(let method):
            print("     → methodNotSupported: サポートされていない抽出方法 (\(method))")
        case .invalidPattern(let pattern):
            print("     → invalidPattern: 無効なパターン (\(pattern))")
        }

        // AIレスポンスがある場合は出力
        if let aiResponse = extractionError.aiResponse {
            print("\n   - AIレスポンス全文:")
            print("     \(aiResponse)")
        }
    } else {
        print("   - その他のエラー: \(error)")
    }

    print("\n📌 期待フィールド:")
    for field in expectedFields {
        print("   - \(field)")
    }

    print(String(repeating: "!", count: 80))
    print("\n")

    var structuredLog: [String: Any] = [
        "pattern": testPattern,
        "level": level,
        "iteration": iteration,
        "method": experiment.method.rawValue,
        "language": experiment.language.rawValue,
        "experiment_pattern": pattern.rawValue,
        "request_content": requestContent ?? NSNull(),
        "error": error.localizedDescription,
        "error_type": String(describing: type(of: error)),
        "expected_fields": [],
        "unexpected_fields": []
    ]

    // 外部LLMエラーの場合はAIレスポンスを含める
    if let extractionError = error as? ExtractionError,
       let aiResponse = extractionError.aiResponse {
        structuredLog["ai_response"] = aiResponse
    }
    
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
            let logFileName = "\(experiment.testcase)_\(experiment.algo)_\(experiment.method.rawValue)_\(experiment.language.rawValue)_level\(level)_run\(runNumber)_error.json"
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
    // testcase名からディレクトリ名へのマッピング
    let testcaseDirMap: [String: String] = [
        "chat": "Chat",
        "contract": "Contract",
        "creditcard": "CreditCard",
        "password": "PasswordManager",
        "voice": "VoiceRecognition"
    ]

    // マッピングテーブルから検索
    if let mapped = testcaseDirMap[pattern.lowercased()] {
        return mapped
    }

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

/// パターンとレベルに基づいて期待フィールドを取得（テストデータファイルから動的に読み込み）
@available(iOS 26.0, macOS 26.0, *)
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

/// AccountInfoから指定フィールドの値を取得
@available(iOS 26.0, macOS 26.0, *)
func getFieldValue(_ accountInfo: AccountInfo, fieldName: String) -> String? {
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



/// プロンプトデバッグ実行関数
@available(iOS 26.0, macOS 26.0, *)
@MainActor
func runPromptDebug() async {
    print("\n🔍 プロンプトデバッグモード")
    print("📝 指定されたパターンのプロンプトを確認")
    print(String(repeating: "=", count: 80))
    
    // 引数からパターンを取得
    guard let experiment = extractExperimentFromArguments() else {
        print("❌ パターンが指定されていません")
        print("使用例: --debug-prompt --method json --testcase strict --language ja")
        return
    }
    
    print("📋 指定されたパターン:")
    print("  方法: \(experiment.method.rawValue)")
    print("  言語: \(experiment.language.rawValue)")
    print("  テストケース: \(experiment.testcase)")
    print("  アルゴリズム: \(experiment.algos.joined(separator: ", "))")
    print()
    
    // 最初のアルゴリズムを使用してパターンを生成
    let methodSuffix = experiment.method.rawValue == "generable" ? "gen" : experiment.method.rawValue
    let patternName = "\(experiment.algos.first ?? "strict")_\(methodSuffix)"
    guard let pattern = ExperimentPattern.allCases.first(where: { $0.rawValue == patternName }) else {
        print("❌ 無効なパターン組み合わせ: \(patternName)")
        print("   有効な組み合わせ: testcase + algo + method")
        return
    }
    
    print("📋 生成されたパターン:")
    print("  パターン名: \(pattern.rawValue)")
    print()
    
    // プロンプト生成（ベースプロンプト）
    let processor = CommonExtractionProcessor()
    do {
        let basePrompt = try processor.generatePrompt(method: experiment.method, algo: experiment.algos.first ?? "strict", language: experiment.language)
        
        print("📝 生成されたベースプロンプト:")
        print(String(repeating: "=", count: 80))
        print(basePrompt)
        print(String(repeating: "=", count: 80))
        print()
        
        // 実際のテストデータ付きの完全なプロンプトを生成
        print("🔗 実際に使用されるプロンプト（テストデータ付き完全版）:")
        print(String(repeating: "=", count: 80))
        
        // テストデータを読み込み
        let testData = try processor.loadTestData(testcase: experiment.testcase, level: 1, language: experiment.language)
        
        // 完全なプロンプトを生成
        let completedPrompt = processor.completePrompt(basePrompt: basePrompt, testData: testData, language: experiment.language)
        
        print(completedPrompt)
        print(String(repeating: "=", count: 80))
        
    } catch {
        print("❌ プロンプト生成エラー: \(error.localizedDescription)")
    }
    print()
    
}



/// @ai[2025-01-19 00:10] AIレスポンス収集機能
/// 目的: chat_abs_json_jaのlevel1-3のAIレスポンスを各10回ずつ収集し、検証用データセットを作成
/// 背景: AIの生のレスポンスを分析して、パフォーマンス改善のためのデータを収集
/// 意図: 実際のAI応答パターンを把握し、プロンプト改善やエラーハンドリングの最適化に活用
@available(iOS 26.0, macOS 26.0, *)
func runResponseCollection() async {
    print("\n🔍 AIレスポンス収集モード")
    print("📝 chat_abs_json_jaのlevel1-3のAIレスポンスを各10回ずつ収集")
    print(String(repeating: "=", count: 80))
    
    // 保存先ディレクトリの確認・作成
    let outputDir = "/Users/t.miyano/repos/AITest/Tests/TestData/AFMResponseExamples"
    let fileManager = FileManager.default
    
    if !fileManager.fileExists(atPath: outputDir) {
        do {
            try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true, attributes: nil)
            print("📁 出力ディレクトリを作成: \(outputDir)")
    } catch {
            print("❌ ディレクトリ作成失敗: \(error)")
            return
        }
    }
    
    // テストケースの定義
    let testCases = [
        ("level1", "Tests/TestData/Chat/Level1_Basic.txt"),
        ("level2", "Tests/TestData/Chat/Level2_General.txt"),
        ("level3", "Tests/TestData/Chat/Level3_Complex.txt")
    ]
    
    // 各レベルで10回ずつ実行
    for (level, testDataPath) in testCases {
        print("\n📋 \(level.uppercased()) のレスポンス収集開始")
        print(String(repeating: "-", count: 40))
        
        // テストデータの読み込み（expectedFieldsコメントを除外）
        guard let testDataFile = try? parseTestDataFile(at: testDataPath) else {
            print("❌ テストデータの読み込み失敗: \(testDataPath)")
            continue
        }
        let testData = testDataFile.cleanContent

        print("📝 テストデータ: \(testDataPath)")
        print("📄 入力テキスト: \(testData.prefix(100))...")
        
        // 10回実行
        for run in 1...10 {
            print("\n🔄 実行 \(run)/10")
            
            do {
                // 新しい統一抽出器を作成
                let factory = ExtractorFactory()
                let modelExtractor = factory.createExtractor(externalLLMConfig: nil as LLMConfig?)
                let unifiedExtractor = UnifiedExtractor(modelExtractor: modelExtractor)
                
                print("📝 新しい統一フローで抽出開始")

                // 新しい統一フローで抽出実行
                let (accountInfo, metrics, rawResponse, requestContent, _) = try await unifiedExtractor.extract(
                    testcase: "Chat",
                    level: level == "level1" ? 1 : level == "level2" ? 2 : 3,
                    method: .json,
                    algo: "abs",
                    language: .japanese,
                    useTwoSteps: ExtractionMode.simple.useTwoSteps // デフォルトは単純推定
                )
                
                // 生のレスポンスをファイルに保存
                let fileName = "\(level)_run\(String(format: "%02d", run))_response.txt"
                let filePath = "\(outputDir)/\(fileName)"
                
                // 生のレスポンスを保存
                let responseContent = """
                # AI Response Collection
                Level: \(level)
                Run: \(run)
                Extraction Time: \(String(format: "%.3f", metrics.extractionTime)) seconds
                Timestamp: \(Date())
                
                # Request Content
                \(requestContent ?? "No request content available")
                
                # Raw AI Response
                \(rawResponse)
                
                # Extracted AccountInfo
                Title: \(accountInfo.title ?? "nil")
                UserID: \(accountInfo.userID ?? "nil")
                Password: \(accountInfo.password ?? "nil")
                URL: \(accountInfo.url ?? "nil")
                Note: \(accountInfo.note ?? "nil")
                Host: \(accountInfo.host ?? "nil")
                Port: \(accountInfo.port?.description ?? "nil")
                AuthKey: \(accountInfo.authKey ?? "nil")
                Confidence: \(accountInfo.confidence?.description ?? "nil")
                
                # Note
                This response was generated using the new unified extraction flow.
                The raw response text is now accessible for analysis.
                """
                
                try responseContent.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
                
                print("✅ レスポンス保存完了: \(fileName)")
                print("⏱️  抽出時間: \(String(format: "%.3f", metrics.extractionTime))秒")
        
    } catch {
                print("❌ 実行 \(run) でエラー: \(error.localizedDescription)")
                
                // エラー情報もファイルに保存
                let fileName = "\(level)_run\(String(format: "%02d", run))_error.txt"
                let filePath = "\(outputDir)/\(fileName)"
                let errorContent = """
                # AI Response Collection - Error
                Level: \(level)
                Run: \(run)
                Error: \(error.localizedDescription)
                Timestamp: \(Date())
                """
                
                try? errorContent.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
            }
            
            // 実行間隔を空ける（API制限対策）
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        }
        
        print("✅ \(level.uppercased()) の収集完了")
    }
    
    print("\n🎉 レスポンス収集完了")
    print("📁 保存先: \(outputDir)")
    print("📊 収集内容: chat_abs_json_jaのlevel1-3を各10回ずつ")
    print(String(repeating: "=", count: 80))
}
