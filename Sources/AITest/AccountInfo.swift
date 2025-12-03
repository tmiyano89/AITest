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
    /// @ai[2025-12-03 18:24] CodingKeysをpublicに変更
    /// 目的: FieldValidatorで型安全にフィールドを参照するため
    /// 背景: 完全一致が必要なフィールドをSet<CodingKeys>で管理するため
    /// 意図: 型定義の恩恵を受けるため
    public enum CodingKeys: String, CodingKey {
        case title
        case userID
        case password
        case url
        case number
        case note
        case host
        case port
        case authKey
        case confidence
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
}

/// @ai[2025-12-03 18:19] フィールドバリデーター
/// 目的: 抽出されたフィールド値がソーステキストに含まれているかをチェック
/// 背景: userID, password, url, host, portなど正確な抜き出しが要求される項目の検証
/// 意図: ソーステキストに基づくシンプルな検証機能を提供
@available(iOS 26.0, macOS 26.0, *)
public struct FieldValidator: Sendable {
    /// @ai[2025-12-03 18:24] 完全一致が必要なフィールドのセット
    /// 目的: 正確な抜き出しが要求されるフィールドを型安全に定義
    /// 背景: titleやnoteは意味的な整合性でOKだが、userID, password, url, number, host, port, authKeyは完全一致が必要
    /// 意図: CodingKeysを使用することで型定義の恩恵を受ける
    public static let exactMatchRequiredFields: Set<AccountInfo.CodingKeys> = [
        .userID,      // ユーザーIDは完全一致が必要
        .password,    // パスワードは完全一致が必要
        .url,         // URLは完全一致が必要
        .number,      // 識別番号は完全一致が必要
        .host,        // ホスト名/IPアドレスは完全一致が必要
        .port,        // ポート番号は完全一致が必要
        .authKey      // 認証キーは完全一致が必要
    ]
    
    /// ソーステキスト（検証対象の元のドキュメント）
    public let sourceText: String
    
    /// イニシャライザ
    public init(sourceText: String) {
        self.sourceText = sourceText
    }
    
    /// フィールドの検証結果
    public struct FieldCheckResult: Sendable {
        /// 検証が成功したかどうか
        public let isValid: Bool
        /// 検証失敗時の理由（nilの場合は成功）
        public let reason: String?
        
        public init(isValid: Bool, reason: String? = nil) {
            self.isValid = isValid
            self.reason = reason
        }
        
        /// 成功結果
        public static var success: FieldCheckResult {
            FieldCheckResult(isValid: true)
        }
        
        /// 失敗結果
        public static func failure(_ reason: String) -> FieldCheckResult {
            FieldCheckResult(isValid: false, reason: reason)
        }
    }
    
    /// フィールドチェック関数（CodingKeysベース）
    /// @ai[2025-12-03 18:24] 個別のcheckXXX関数を削除し、checkField関数一つに統一
    /// 目的: コードの重複を排除し、保守性を向上させる
    /// 背景: 全てのcheckXXX関数が同じロジック（ソーステキストに値が含まれているかをチェック）を実装していた
    /// 意図: 抽象化により、一つの関数で全てのフィールドをチェックできるようにする
    /// - Parameters:
    ///   - field: フィールドのCodingKeys
    ///   - value: 抽出された値（StringまたはInt）
    /// - Returns: 検証結果
    public func checkField(_ field: AccountInfo.CodingKeys, value: Any?) -> FieldCheckResult {
        // 完全一致が必要なフィールドのみチェック
        guard Self.exactMatchRequiredFields.contains(field) else {
            return .success // チェック対象外のフィールドは常に成功
        }
        
        // 値がnilの場合は成功
        guard let value = value else {
            return .success
        }
        
        // 値の文字列表現を取得
        let valueString: String
        if let stringValue = value as? String {
            valueString = stringValue
        } else if let intValue = value as? Int {
            valueString = String(intValue)
        } else {
            return .success // サポートされていない型は検証対象外
        }
        
        // 空文字列の場合は成功
        guard !valueString.isEmpty else {
            return .success
        }
        
        // ソーステキストに同一のテキストが含まれているかをチェック
        if sourceText.contains(valueString) {
            return .success
        } else {
            return .failure("\(field.rawValue) '\(valueString)' がソーステキストに見つかりません")
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
    
    /// イニシャライザ
    public init(
        extractionTime: TimeInterval,
        totalTime: TimeInterval,
        memoryUsed: Double,
        textLength: Int,
        extractedFieldsCount: Int,
        confidence: Double
    ) {
        self.extractionTime = extractionTime
        self.totalTime = totalTime
        self.memoryUsed = memoryUsed
        self.textLength = textLength
        self.extractedFieldsCount = extractedFieldsCount
        self.confidence = confidence
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

