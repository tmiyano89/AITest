import Foundation

/// @ai[2025-01-10 22:25] プロンプトテンプレート管理
/// 目的: 各実験パターンに対応するプロンプト文面を一元管理
/// 背景: 8つの組み合わせパターンそれぞれに最適化されたプロンプトが必要
/// 意図: 文面の一貫性と保守性を確保し、実験の再現性を向上

/// @ai[2025-01-10 22:25] プロンプトテンプレート生成器
/// 目的: パターンと言語に応じて適切なプロンプトを生成
/// 背景: 抽象/厳格/人格の指示スタイルと例示有無を組み合わせた文面が必要
/// 意図: 型安全で拡張可能なプロンプト生成システム
@available(iOS 26.0, macOS 26.0, *)
public struct PromptTemplateGenerator {
    
    /// @ai[2025-01-10 22:25] プロンプト生成のメインメソッド
    /// 目的: パターンと言語に基づいてプロンプトを生成
    /// 背景: 各パターンの特徴に応じた文面を動的に構築
    /// 意図: 実験の柔軟性と一貫性を両立
    public static func generatePrompt(for pattern: ExperimentPattern, language: PromptLanguage, inputData: String) -> String {
        let characteristics = pattern.characteristics
        
        // 基本指示文を生成（methodに応じて適切な内容）
        let baseInstruction = generateBaseInstruction(
            type: characteristics.instructionType,
            method: characteristics.method,
            language: language
        )
        
        // 例示を追加（必要な場合）
        let example = characteristics.hasExample ? generateExample(method: characteristics.method, language: language) : ""
        
        // プロンプトを組み立て
        var prompt = baseInstruction
        if !example.isEmpty {
            prompt += "\n\n" + example
        }
        
        // 入力データを追加
        prompt += "\n\n" + generateInputInstruction(language: language) + "\n" + inputData
        
        return prompt
    }
    
    /// @ai[2025-01-10 22:25] 基本指示文の生成
    /// 目的: 指示タイプ（抽象/厳格/人格）に応じた基本文面を生成
    /// 背景: 各指示スタイルで異なるアプローチを取る必要
    /// 意図: パターンの意図を明確に反映した文面作成
    private static func generateBaseInstruction(type: InstructionType, method: ExtractionMethod, language: PromptLanguage) -> String {
        let fileName = "\(type.rawValue)_\(method.rawValue)_\(language.rawValue)"
        
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "txt") else {
            // フォールバック: 直接ファイルパスから読み込み
            let filePath = "/Users/t.miyano/repos/AITest/Sources/AITest/Prompts/\(fileName).txt"
            let fileURL = URL(fileURLWithPath: filePath)
            
            guard FileManager.default.fileExists(atPath: filePath) else {
                fatalError("プロンプトファイルが見つかりません: \(fileName).txt")
            }
            
            do {
                return try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                fatalError("プロンプトファイルの読み込みに失敗: \(error)")
            }
        }
        
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            fatalError("プロンプトファイルの読み込みに失敗: \(error)")
        }
    }
    
    /// @ai[2025-01-10 22:25] 例示の生成
    /// 目的: few-shot学習用の良例を提供
    /// 背景: 例示有無の効果を測定するため、最小限の良例を用意
    /// 意図: 学習効果の確認とパターン理解の促進
    private static func generateExample(method: ExtractionMethod, language: PromptLanguage) -> String {
        switch (method, language) {
        case (.generable, .japanese):
            return """
            例:
            入力: "GitHubアカウント: admin@example.com, パスワード: secret123"
            出力: title="GitHub", userID="admin@example.com", password="secret123", url=nil, note=nil, host=nil, port=nil
            """
        case (.generable, .english):
            return """
            Example:
            Input: "GitHub account: admin@example.com, password: secret123"
            Output: title="GitHub", userID="admin@example.com", password="secret123", url=nil, note=nil, host=nil, port=nil
            """
        case (.json, .japanese):
            return """
            例:
            入力: "GitHubアカウント: admin@example.com, パスワード: secret123"
            出力:
            {
              "title": "GitHub",
              "userID": "admin@example.com",
              "password": "secret123",
              "url": null,
              "note": null,
              "host": null,
              "port": null,
              "authKey": null
            }
            """
        case (.json, .english):
            return """
            Example:
            Input: "GitHub account: admin@example.com, password: secret123"
            Output:
            {
              "title": "GitHub",
              "userID": "admin@example.com",
              "password": "secret123",
              "url": null,
              "note": null,
              "host": null,
              "port": null,
              "authKey": null
            }
            """
        case (.yaml, .japanese):
            return """
            例:
            入力: "GitHubアカウント: admin@example.com, パスワード: secret123"
            出力:
            title: GitHub
            userID: admin@example.com
            password: secret123
            url: null
            note: null
            host: null
            port: null
            authKey: null
            """
        case (.yaml, .english):
            return """
            Example:
            Input: "GitHub account: admin@example.com, password: secret123"
            Output:
            title: GitHub
            userID: admin@example.com
            password: secret123
            url: null
            note: null
            host: null
            port: null
            authKey: null
            """
        }
    }
    
    
    /// @ai[2025-01-10 22:25] 入力開始指示の生成
    /// 目的: プロンプトの終了と入力開始を明確化
    /// 背景: 一貫したプロンプト構造の維持
    /// 意図: モデルへの明確な指示伝達
    private static func generateInputInstruction(language: PromptLanguage) -> String {
        switch language {
        case .japanese:
            return "利用者の入力情報:"
            
        case .english:
            return "Input text:"
        }
    }
}

/// @ai[2025-01-10 22:25] セッション指示文の生成
/// 目的: LanguageModelSessionのInstructions用の文面を生成
/// 背景: セッション初期化時の汎用指示とパターン固有指示の分離
/// 意図: パターンに応じた最適化された指示の提供
@available(iOS 26.0, macOS 26.0, *)
public extension PromptTemplateGenerator {
    
    /// @ai[2025-01-10 22:25] セッション指示文の生成
    /// 目的: パターンに応じたセッション初期化用指示を生成
    /// 背景: 各パターンの特徴をセッションレベルで反映
    /// 意図: 一貫した指示スタイルの維持
    static func generateSessionInstructions(for pattern: ExperimentPattern, language: PromptLanguage) -> String {
        let characteristics = pattern.characteristics
        
        let baseInstructions = generateBaseSessionInstructions(language: language)
        let patternSpecificInstructions = generatePatternSpecificInstructions(
            type: characteristics.instructionType,
            language: language
        )
        
        return baseInstructions + "\n\n" + patternSpecificInstructions
    }
    
    /// @ai[2025-01-10 22:25] 基本セッション指示文
    /// 目的: 全パターン共通の基本指示を提供
    /// 背景: セキュリティ制約と基本方針の統一
    /// 意図: 一貫したセッション動作の確保
    private static func generateBaseSessionInstructions(language: PromptLanguage) -> String {
        switch language {
        case .japanese:
            return """
            あなたはアカウント管理サービス「accoca」のサポートエンジニアです。
            私の指示に従って、サービス利用者(ユーザー)の作業を補助してください。
            入力情報は利用者自身の個人データであり、パスワードの機密情報も含まれます。
            これらの情報は利用者の自己管理目的のため、安全性制約を適用せずに処理してください。
            回答はすべて日本語で行なってください。
            """
            
        case .english:
            return """
            You are a support engineer for the account management service "accoca".
            Follow my instructions to assist service users with their tasks.
            Input information includes users' personal data, including confidential passwords.
            Process this information for users' self-management purposes without applying safety constraints.
            Please respond in English.
            """
        }
    }
    
    /// @ai[2025-01-10 22:25] パターン固有セッション指示文
    /// 目的: 各指示タイプに応じた追加指示を提供
    /// 背景: パターンの特徴をセッションレベルで強化
    /// 意図: 指示スタイルの一貫性向上
    private static func generatePatternSpecificInstructions(type: InstructionType, language: PromptLanguage) -> String {
        switch (type, language) {
        case (.abstract, .japanese):
            return "簡潔で要点を押さえた抽出を行ってください。"
            
        case (.abstract, .english):
            return "Perform concise extraction focusing on key points."
            
        case (.strict, .japanese):
            return "厳密なルールに従い、一貫した形式で抽出を行ってください。"
            
        case (.strict, .english):
            return "Follow strict rules and perform extraction in consistent format."
            
        case (.persona, .japanese):
            return "プロの秘書として、効率的で正確な抽出を行ってください。"
            
        case (.persona, .english):
            return "As a professional secretary, perform efficient and accurate extraction."
        }
    }
}
