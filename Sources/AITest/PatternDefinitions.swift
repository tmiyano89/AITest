import Foundation

/// @ai[2025-01-18 12:05] 抽出方法の定義
/// 目的: アカウント情報抽出の方法を型安全に管理
/// 背景: @Generable、JSON、YAMLの3つの方法を統一
/// 意図: 各方法の特徴を明確化し、プロンプト生成を最適化
@available(iOS 26.0, macOS 26.0, *)
public enum ExtractionMethod: String, CaseIterable, Codable, Sendable {
    case generable = "generable"
    case json = "json"
    case yaml = "yaml"
}

/// @ai[2025-01-18 12:05] プロンプト言語の定義
/// 目的: プロンプトの言語を型安全に管理
/// 背景: 日本語と英語の2つの言語に対応
/// 意図: 言語別のプロンプト生成を最適化
@available(iOS 26.0, macOS 26.0, *)
public enum PromptLanguage: String, CaseIterable, Codable, Sendable {
    case japanese = "ja"
    case english = "en"
    
    public var displayName: String {
        switch self {
        case .japanese:
            return "日本語"
        case .english:
            return "English"
        }
    }
}

/// @ai[2025-01-10 22:20] 実験パターン定義
/// 目的: @Guideマクロ改善のための組み合わせパターンを一元管理
/// 背景: Instructions/Prompt/@Guide/@Generableの組み合わせでAFMの傾向を把握
/// 意図: 段階的実験による最適化指針の確立

/// @ai[2025-01-10 22:20] 実験パターンの列挙型
/// 目的: 8つの組み合わせパターンを型安全に管理
/// 背景: 抽象/厳格/人格×例示有無×ステップ数×@Generable有無の軸で設計
/// 意図: 各パターンの特徴を明確化し、実験結果の比較を容易にする
@available(iOS 26.0, macOS 26.0, *)
public enum ExperimentPattern: String, CaseIterable, Codable, Sendable {
    case absEx0S1Gen = "abs_gen"
    case absEx1S1Gen = "abs-ex_gen"
    case strictEx0S1Gen = "strict_gen"
    case strictEx1S1Gen = "strict-ex_gen"
    case personaEx0S1Gen = "persona_gen"
    case personaEx1S1Gen = "persona-ex_gen"
    
    // 外部LLM実験用JSONパターン
    case absJson = "abs_json"
    case absExJson = "abs-ex_json"
    case strictJson = "strict_json"
    case strictExJson = "strict-ex_json"
    case personaJson = "persona_json"
    case personaExJson = "persona-ex_json"
    
    /// @ai[2025-01-10 22:20] パターンの表示名
    /// 目的: レポートやログで分かりやすい名前を表示
    /// 背景: パターンIDは技術的だが、人間が理解しやすい名前が必要
    /// 意図: 実験結果の可読性向上
    public var displayName: String {
        switch self {
        case .absEx0S1Gen:
            return "Chat・抽象指示・@Generable"
        case .absEx1S1Gen:
            return "Chat・抽象指示(例示)・@Generable"
        case .strictEx0S1Gen:
            return "Chat・厳格指示・@Generable"
        case .strictEx1S1Gen:
            return "Chat・厳格指示(例示)・@Generable"
        case .personaEx0S1Gen:
            return "Chat・人格指示・@Generable"
        case .personaEx1S1Gen:
            return "Chat・人格指示(例示)・@Generable"
        case .absJson:
            return "Chat・抽象指示・JSON"
        case .absExJson:
            return "Chat・抽象指示(例示)・JSON"
        case .strictJson:
            return "Chat・厳格指示・JSON"
        case .strictExJson:
            return "Chat・厳格指示(例示)・JSON"
        case .personaJson:
            return "Chat・人格指示・JSON"
        case .personaExJson:
            return "Chat・人格指示(例示)・JSON"
        }
    }
    
    /// @ai[2025-01-10 22:20] パターンの説明
    /// 目的: 各パターンの詳細な特徴を説明
    /// 背景: 実験結果の解釈時にパターンの意図を理解する必要
    /// 意図: 分析時の文脈提供
    public var description: String {
        switch self {
        case .absEx0S1Gen:
            return "最小限の抽象指示で基本性能を測定。例示なし、1プロンプト、@Generable使用"
        case .absEx1S1Gen:
            return "抽象指示にfew-shot例示を追加。良例1件で学習効果を確認"
        case .strictEx0S1Gen:
            return "厳格な制約ルールで出力品質を向上。推測禁止、形式統一を強調"
        case .strictEx1S1Gen:
            return "厳格制約にfew-shot例示を追加。制約+学習の相乗効果を測定"
        case .personaEx0S1Gen:
            return "プロ秘書の役割を活性化。専門知識と作業パターンの活用"
        case .personaEx1S1Gen:
            return "人格指示にfew-shot例示を追加。役割+学習の相乗効果を測定"
        case .absJson:
            return "抽象指示をJSONフォーマットで実行。外部LLMとの性能比較用"
        case .absExJson:
            return "抽象指示(例示)をJSONフォーマットで実行。外部LLMとの性能比較用"
        case .strictJson:
            return "厳格指示をJSONフォーマットで実行。外部LLMとの性能比較用"
        case .strictExJson:
            return "厳格指示(例示)をJSONフォーマットで実行。外部LLMとの性能比較用"
        case .personaJson:
            return "人格指示をJSONフォーマットで実行。外部LLMとの性能比較用"
        case .personaExJson:
            return "人格指示(例示)をJSONフォーマットで実行。外部LLMとの性能比較用"
        }
    }
    
    /// @ai[2025-01-10 22:20] パターンの特徴フラグ
    /// 目的: 各パターンの技術的特徴を構造化
    /// 背景: 実験結果の分析時に軸別の効果を測定する必要
    /// 意図: 統計分析のためのメタデータ提供
    public var characteristics: PatternCharacteristics {
        switch self {
        case .absEx0S1Gen:
            return PatternCharacteristics(
                instructionType: .abstract,
                hasExample: false,
                method: .generable
            )
        case .absEx1S1Gen:
            return PatternCharacteristics(
                instructionType: .abstract,
                hasExample: true,
                method: .generable
            )
        case .strictEx0S1Gen:
            return PatternCharacteristics(
                instructionType: .strict,
                hasExample: false,
                method: .generable
            )
        case .strictEx1S1Gen:
            return PatternCharacteristics(
                instructionType: .strict,
                hasExample: true,
                method: .generable
            )
        case .personaEx0S1Gen:
            return PatternCharacteristics(
                instructionType: .persona,
                hasExample: false,
                method: .generable
            )
        case .personaEx1S1Gen:
            return PatternCharacteristics(
                instructionType: .persona,
                hasExample: true,
                method: .generable
            )
        case .absJson:
            return PatternCharacteristics(
                instructionType: .abstract,
                hasExample: false,
                method: .json
            )
        case .absExJson:
            return PatternCharacteristics(
                instructionType: .abstract,
                hasExample: true,
                method: .json
            )
        case .strictJson:
            return PatternCharacteristics(
                instructionType: .strict,
                hasExample: false,
                method: .json
            )
        case .strictExJson:
            return PatternCharacteristics(
                instructionType: .strict,
                hasExample: true,
                method: .json
            )
        case .personaJson:
            return PatternCharacteristics(
                instructionType: .persona,
                hasExample: false,
                method: .json
            )
        case .personaExJson:
            return PatternCharacteristics(
                instructionType: .persona,
                hasExample: true,
                method: .json
            )
        }
    }
}

/// @ai[2025-01-10 22:20] 指示タイプの列挙型
/// 目的: 抽象/厳格/人格の3つの指示スタイルを分類
/// 背景: 異なる指示スタイルが抽出精度に与える影響を測定
/// 意図: 軸別分析のための型安全な分類
@available(iOS 26.0, macOS 26.0, *)
public enum InstructionType: String, CaseIterable, Codable, Sendable {
    case abstract = "abstract"
    case strict = "strict"
    case persona = "persona"
    
    public var displayName: String {
        switch self {
        case .abstract:
            return "抽象指示"
        case .strict:
            return "厳格指示"
        case .persona:
            return "人格指示"
        }
    }
}

/// @ai[2025-01-10 22:20] パターン特徴の構造体
/// 目的: 各パターンの技術的特徴を構造化して管理
/// 背景: 実験結果の統計分析時に軸別の効果を測定する必要
/// 意図: メタデータによる分析の自動化
@available(iOS 26.0, macOS 26.0, *)
public struct PatternCharacteristics: Codable, Sendable {
    public let instructionType: InstructionType
    public let hasExample: Bool
    public let method: ExtractionMethod
    
    public init(instructionType: InstructionType, hasExample: Bool, method: ExtractionMethod) {
        self.instructionType = instructionType
        self.hasExample = hasExample
        self.method = method
    }
}

/// @ai[2025-01-10 22:20] デフォルトパターンの定義
/// 目的: 実験開始時のデフォルトパターンを指定
/// 背景: 段階的実験で最初に実行するパターンを明確化
/// 意図: 実験の一貫性と再現性の確保
@available(iOS 26.0, macOS 26.0, *)
public extension ExperimentPattern {
    static let defaultPattern: ExperimentPattern = .absEx0S1Gen
    
    /// @ai[2025-01-10 22:20] 小規模実験用パターンセット
    /// 目的: 初期の傾向把握用に代表的なパターンを選択
    /// 背景: 全8パターンではなく、差が出やすい代表例で開始
    /// 意図: 効率的な初期分析
    static let initialTestPatterns: [ExperimentPattern] = [
        .absEx0S1Gen,      // 基本性能
        .strictEx0S1Gen,   // 制約効果
        .personaEx0S1Gen,  // 人格効果
    ]
}
