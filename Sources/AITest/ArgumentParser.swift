import Foundation

/// @ai[2025-01-19 01:00] コマンドライン引数解析ユーティリティ
/// 目的: コマンドライン引数の解析を一元化
/// 背景: main.swiftの肥大化を防ぐため、引数解析ロジックを分離
/// 意図: 保守性の向上とコードの可読性向上

/// 有効なパターン名の定義
/// @ai[2025-01-10 20:15] 有効なパターン名の定義
/// 目的: パターン名のリテラルを一元管理して保守性を向上
/// 背景: 複数箇所で同じパターン名が重複定義されており、変更時のリスクが高い
/// 意図: 単一の真実の源（Single Source of Truth）として定数で管理
public let VALID_PATTERNS = ["Chat", "Contract", "CreditCard", "VoiceRecognition", "PasswordManager"]

/// タイムアウト設定を引数から抽出
public func extractTimeoutFromArguments() -> Int? {
    for argument in CommandLine.arguments {
        if argument.hasPrefix("--timeout=") {
            let timeoutString = String(argument.dropFirst("--timeout=".count))
            return Int(timeoutString)
        }
    }
    return nil
}

/// パターン名を引数から抽出
public func extractPatternFromArguments() -> String? {
    for argument in CommandLine.arguments {
        if argument.hasPrefix("--pattern=") {
            return String(argument.dropFirst("--pattern=".count))
        }
    }
    return nil
}

/// 外部LLM設定を引数から抽出
@available(iOS 26.0, macOS 26.0, *)
public func extractExternalLLMConfigFromArguments() -> LLMConfig? {
    var baseURL: String?
    var apiKey: String?
    var model: String?
    
    for argument in CommandLine.arguments {
        if argument.hasPrefix("--external-llm-url=") {
            baseURL = String(argument.dropFirst("--external-llm-url=".count))
        } else if argument.hasPrefix("--external-llm-key=") {
            apiKey = String(argument.dropFirst("--external-llm-key=".count))
        } else if argument.hasPrefix("--external-llm-model=") {
            model = String(argument.dropFirst("--external-llm-model=".count))
        }
    }
    
    guard let baseURL = baseURL, let apiKey = apiKey, let model = model else {
        return nil
    }
    
    return LLMConfig(baseURL: baseURL, apiKey: apiKey, model: model)
}

/// 引数の妥当性を検証
@available(iOS 26.0, macOS 26.0, *)
public func validateArguments() -> (isValid: Bool, errors: [String]) {
    var errors: [String] = []
    
    // タイムアウト値の検証
    if let timeout = extractTimeoutFromArguments() {
        if timeout <= 0 {
            errors.append("タイムアウト値は正の整数である必要があります")
        }
    }
    
    // パターン名の検証
    if let pattern = extractPatternFromArguments() {
        if !VALID_PATTERNS.contains(pattern) {
            errors.append("無効なパターン名: \(pattern). 有効なパターン: \(VALID_PATTERNS.joined(separator: ", "))")
        }
    }
    
    // 外部LLM設定の検証
    if let config = extractExternalLLMConfigFromArguments() {
        if config.baseURL.isEmpty {
            errors.append("外部LLMのURLが空です")
        }
        if config.apiKey.isEmpty {
            errors.append("外部LLMのAPIキーが空です")
        }
        if config.model.isEmpty {
            errors.append("外部LLMのモデル名が空です")
        }
    }
    
    return (errors.isEmpty, errors)
}

/// ヘルプメッセージを表示
public func printHelp() {
    print("\n📖 AITestApp 使用方法:")
    print("  --timeout=<秒数>          タイムアウト時間を設定")
    print("  --pattern=<パターン名>    テストパターンを指定")
    print("  --external-llm-url=<URL> 外部LLMのURLを指定")
    print("  --external-llm-key=<キー> 外部LLMのAPIキーを指定")
    print("  --external-llm-model=<モデル> 外部LLMのモデル名を指定")
    print("  --method=<メソッド>       抽出メソッドを指定 (json, generable)")
    print("  --language=<言語>         言語を指定 (ja, en)")
    print("  --testcase=<テストケース> テストケースを指定")
    print("  --algo=<アルゴリズム>     アルゴリズムを指定")
    print("  --help                    このヘルプを表示")
    print("\n有効なパターン: \(VALID_PATTERNS.joined(separator: ", "))")
}

/// 実験設定を引数から抽出
@available(iOS 26.0, macOS 26.0, *)
public func extractExperimentFromArguments() -> (method: ExtractionMethod, language: PromptLanguage, testcase: String, algos: [String], mode: ExtractionMode, levels: [Int])? {
    print("🔍 extractExperimentFromArguments 開始")

    var method: ExtractionMethod = .json
    var language: PromptLanguage = .japanese
    var testcase: String = "Chat"
    var algos: [String] = ["abs"]
    var mode: ExtractionMode = .simple  // デフォルト
    var levels: [Int] = [1, 2, 3]  // デフォルトは全レベル

    var i = 0
    while i < CommandLine.arguments.count {
        let argument = CommandLine.arguments[i]

        if argument.hasPrefix("--method=") {
            let methodString = String(argument.dropFirst("--method=".count))
            switch methodString.lowercased() {
            case "json":
                method = .json
            case "generable":
                method = .generable
            default:
                print("❌ 無効なメソッド: \(methodString)")
                return nil
            }
        } else if argument.hasPrefix("--language=") {
            let languageString = String(argument.dropFirst("--language=".count))
            switch languageString.lowercased() {
            case "ja", "japanese":
                language = .japanese
            case "en", "english":
                language = .english
            default:
                print("❌ 無効な言語: \(languageString)")
                return nil
            }
        } else if argument.hasPrefix("--testcase=") {
            testcase = String(argument.dropFirst("--testcase=".count))
        } else if argument.hasPrefix("--algo=") {
            algos = [String(argument.dropFirst("--algo=".count))]
        } else if argument.hasPrefix("--algos=") {
            let algosString = String(argument.dropFirst("--algos=".count))
            algos = algosString.split(separator: ",").map(String.init)
        } else if argument.hasPrefix("--mode=") {
            let modeString = String(argument.dropFirst("--mode=".count))
            switch modeString.lowercased() {
            case "simple":
                mode = .simple
            case "two-steps":
                mode = .twoSteps
            default:
                print("❌ 無効なモード: \(modeString)")
                return nil
            }
        } else if argument == "--mode" && i + 1 < CommandLine.arguments.count {
            let modeString = CommandLine.arguments[i + 1]
            switch modeString.lowercased() {
            case "simple":
                mode = .simple
            case "two-steps":
                mode = .twoSteps
            default:
                print("❌ 無効なモード: \(modeString)")
                return nil
            }
            i += 1  // スキップ
        } else if argument.hasPrefix("--levels=") {
            let levelsString = String(argument.dropFirst("--levels=".count))
            let levelStrings = levelsString.split(separator: ",").map(String.init)
            levels = levelStrings.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            if levels.isEmpty {
                print("❌ 無効なレベル指定: \(levelsString)")
                return nil
            }
        } else if argument == "--levels" && i + 1 < CommandLine.arguments.count {
            let levelsString = CommandLine.arguments[i + 1]
            let levelStrings = levelsString.split(separator: ",").map(String.init)
            levels = levelStrings.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            if levels.isEmpty {
                print("❌ 無効なレベル指定: \(levelsString)")
                return nil
            }
            i += 1  // スキップ
        }

        i += 1
    }

    print("✅ 実験設定: method=\(method.rawValue), language=\(language.rawValue), testcase=\(testcase), algos=\(algos.joined(separator: ", ")), mode=\(mode.rawValue), levels=\(levels.map(String.init).joined(separator: ", "))")
    return (method, language, testcase, algos, mode, levels)
}

/// テストディレクトリを引数から抽出
public func extractTestDirFromArguments() -> String? {
    let arguments = CommandLine.arguments
    
    for i in 0..<arguments.count {
        if arguments[i] == "--test-dir" && i + 1 < arguments.count {
            return arguments[i + 1]
        } else if arguments[i].hasPrefix("--test-dir=") {
            return String(arguments[i].dropFirst("--test-dir=".count))
        }
    }
    
    return nil
}
