# 分割推定方式設計ドキュメント

## 概要
- 目的: モデルの推測処理を2回実行することで精度を高めるアプローチの実装
- 背景: 現在のUnifiedExtractorの単純推定方式に加えて、より高精度な抽出方法を提供
- 意図: ドキュメントタイプの事前判定により、適切な抽出戦略を選択し、精度向上を実現

## 現在のアーキテクチャ分析（単純推定方式）

### 既存のUnifiedExtractor構造
- **共通処理**: `CommonExtractionProcessor`でプロンプト生成、テストデータ読み込み、メトリクス作成を統一
- **モデル抽象化**: `ModelExtractor`プロトコルでFoundationModelsとExternalLLMを抽象化
- **1回の推定**: プロンプト前段生成 → プロンプト完成 → モデル抽出 → メトリクス作成（4段階のフローで1回の推定を実行）

### 既存のAccountInfo構造
- `@Generable`マクロによる構造化された抽出
- 8つの主要フィールド（title, userID, password, url, note, host, port, authKey）
- バリデーション機能と信頼度スコア

## 分割推定方式アーキテクチャ

### 基本コンセプト
1. **推定1**: ドキュメントのタイプと含まれる情報の種類を判定（4段階フローで1回目の推定を実行）
2. **推定2**: 判定結果に基づいて、適切な抽出戦略でアカウント情報を抽出（4段階フローで2回目の推定を実行）

### 推定方式の比較
- **単純推定方式**: 1回の推定でアカウント情報を直接抽出
- **分割推定方式**: 2回の推定により、まずドキュメントタイプを判定し、その後適切な戦略でアカウント情報を抽出

### 新しいデータ構造

#### ContentCategory（コンテンツカテゴリ）
```swift
public enum ContentCategory: String, Codable, CaseIterable {
    case home                  // 自宅（公共料金・賃貸・家電アカウント等）
    case schoolAndLessons      // 学校・習い事
    case aiServices            // AIサービス
    case creditCard            // クレジットカード
    case bankCard              // 銀行カード（デビット等含む）
    case mobileApps            // モバイルアプリ
    case shopping              // ショッピング（EC全般）
    case videoMusicSubscription// 動画・音楽サービス（サブスク）
    case telcoAndProviders     // 携帯・通信サービス（携帯/光回線/ISP）
    case paymentServices       // 決済サービス（PayPay/ポイント等）
    case insuranceAndPension   // 保険・年金
    case licensesAndIDs        // 免許・資格・個人カード（運転免許/マイナンバー等）
    case hospital              // 病院・医療ポータル
    case contacts              // 連絡先（友人・知人）
    case finance               // 銀行・証券・仮想通貨
    case work                  // 仕事用（VPS/サーバ/業務SaaS等）
    case games                 // ゲーム
    case sns                   // SNS
}
```

#### ContentInfo（コンテンツ情報）
```swift
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "ドキュメントに含まれる情報の種類とカテゴリ")
public struct ContentInfo: Codable, Equatable {
    /// ドキュメントのカテゴリ
    @Guide(description: "ドキュメントの種類を判定してください(例: 'home', 'creditCard', 'bankCard', 'mobileApps'等)[必須]")
    public var category: ContentCategory
    
    /// ID/パスワード/URL などの一般的ログイン情報
    @Guide(description: "ログインに必要なID、パスワード、URLなどの情報が含まれているか")
    public var hasLoginCredentials: Bool
    
    /// カード番号・有効期限などのクレジットカード情報
    @Guide(description: "クレジットカード番号、有効期限、CVVなどのカード情報が含まれているか")
    public var hasCardInfo: Bool
    
    /// 口座番号・支店番号などの口座情報
    @Guide(description: "銀行口座番号、支店番号、銀行名などの口座情報が含まれているか")
    public var hasBankAccountInfo: Bool
    
    /// 契約者番号・契約開始日などの契約情報
    @Guide(description: "契約者番号、契約開始日、契約期間などの契約情報が含まれているか")
    public var hasContractInfo: Bool
    
    /// サービスの料金プラン（プラン名/料金/更新周期 等）
    @Guide(description: "料金プラン名、月額料金、更新周期などの料金情報が含まれているか")
    public var hasPlanInfo: Bool
    
    /// ログインページ/公式サイト等の URL
    @Guide(description: "ログインページ、公式サイト、サポートページなどのURLが含まれているか")
    public var hasUrls: Bool
    
    /// ホスト名/ポート/IP/プロトコル 等のアクセス方法
    @Guide(description: "サーバーのホスト名、ポート番号、IPアドレス、プロトコルなどのアクセス情報が含まれているか")
    public var hasAccessInfo: Bool
    
    /// 住所/電話番号 等の連絡先情報
    @Guide(description: "住所、電話番号、メールアドレスなどの連絡先情報が含まれているか")
    public var hasContactInfo: Bool
    
    /// 抽出された情報の信頼度（0.0-1.0）
    @Guide(description: "ドキュメントタイプ判定の信頼度", .range(0.0...1.0))
    public var confidence: Double?
    
    public init(
        category: ContentCategory,
        hasLoginCredentials: Bool = false,
        hasCardInfo: Bool = false,
        hasBankAccountInfo: Bool = false,
        hasContractInfo: Bool = false,
        hasPlanInfo: Bool = false,
        hasUrls: Bool = false,
        hasAccessInfo: Bool = false,
        hasContactInfo: Bool = false,
        confidence: Double? = nil
    ) {
        self.category = category
        self.hasLoginCredentials = hasLoginCredentials
        self.hasCardInfo = hasCardInfo
        self.hasBankAccountInfo = hasBankAccountInfo
        self.hasContractInfo = hasContractInfo
        self.hasPlanInfo = hasPlanInfo
        self.hasUrls = hasUrls
        self.hasAccessInfo = hasAccessInfo
        self.hasContactInfo = hasContactInfo
        self.confidence = confidence
    }
}
```

### 推定1フロー設計

#### 目的
ドキュメントの内容を分析し、どのような種類の情報が含まれているかを判定する

#### プロセス（4段階フロー）
1. **プロンプト前段生成**: ドキュメントタイプ判定用のプロンプト前段を作成
2. **プロンプト完成**: テストデータを読み込み、プロンプトを完成させる
3. **モデル抽出**: ドキュメントを提示してContentInfoを抽出
4. **メトリクス作成**: 推定1の処理時間と信頼度を記録

#### プロンプト戦略
- ドキュメント全体を読み込んで、どのようなサービスや情報が含まれているかを判定
- 複数のカテゴリが同時に存在する可能性を考慮
- 各情報タイプの存在フラグを正確に判定

### 推定2フロー設計

#### 目的
推定1の結果に基づいて、適切な抽出戦略でアカウント情報を抽出する

#### プロセス（4段階フロー）
1. **プロンプト前段生成**: ContentInfoの結果に基づいて抽出戦略を決定し、プロンプト前段を作成
2. **プロンプト完成**: テストデータと抽出戦略を組み合わせてプロンプトを完成
3. **モデル抽出**: 段階的抽出を実行（各情報タイプごとに個別のプロンプトで抽出）
4. **メトリクス作成**: 推定2の処理時間と信頼度を記録

#### 分割推定フローの詳細

**推定1: ドキュメントタイプ判定**
1. ドキュメント全体を分析し、ContentInfo構造体を抽出
2. 判定されたカテゴリと情報タイプの存在フラグを取得

**推定2: 段階的アカウント情報抽出**
推定1の結果に基づいて、以下の手順で段階的に情報を抽出：

**例: category: finance, hasLoginCredentials: true, hasCardInfo: true の場合**

1. **ログイン情報の抽出**
   - プロンプト: "添付ドキュメントから、ログイン認証情報を抽出してください。"
   - 出力形式: LoginCredentialsInfo構造体を指定
   - 抽出結果: userID, password, loginURL, serviceName, note

2. **カード情報の抽出**
   - プロンプト: "添付ドキュメントから、カード情報を抽出してください。"
   - 出力形式: CardInfo構造体を指定
   - 抽出結果: cardNumber, expiryDate, cvv, cardholderName, cardCompany, note

3. **情報統合とAccountInfo作成**
   - LoginCredentialsInfoとCardInfoの情報を統合
   - AccountInfoの各フィールドにマッピング：
     - title: serviceName（LoginCredentialsInfo）または cardCompany（CardInfo）
     - userID: userID（LoginCredentialsInfo）
     - password: password（LoginCredentialsInfo）
     - url: loginURL（LoginCredentialsInfo）
     - note: 専用フィールドがない項目をまとめて記録
       - カード情報: "カード番号: {cardNumber}, 有効期限: {expiryDate}, CVV: {cvv}, 名義人: {cardholderName}"
       - その他の補足情報

**他の情報タイプの例**

**hasAccessInfo: true の場合**
- プロンプト: "添付ドキュメントから、アクセス方法に関する情報を抽出してください。"
- 出力形式: AccessInfo構造体を指定
- 統合: host, port, authKeyをAccountInfoにマッピング

**hasBankAccountInfo: true の場合**
- プロンプト: "添付ドキュメントから、銀行口座情報を抽出してください。"
- 出力形式: BankAccountInfo構造体を指定
- 統合: 口座情報をnoteフィールドに記録

**複数情報タイプの組み合わせ**
- 各情報タイプごとに個別のプロンプトで抽出
- 抽出された情報を順次統合
- 重複する情報はあらかじめ定めた固定の優先度に基づいて選択
- すべての情報をnoteフィールドにまとめて記録

**情報統合ルール**
1. **直接マッピング**: AccountInfoの専用フィールドに直接マッピング可能な情報
2. **noteフィールド統合**: 専用フィールドがない情報はnoteに構造化して記録
3. **優先度**: 複数の情報源がある場合、あらかじめ定めた優先度の高い構造体の情報を優先


#### 動的抽出戦略例

##### LoginCredentialsInfo抽出（hasLoginCredentials = trueの場合）
```swift
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "ログイン認証情報")
public struct LoginCredentialsInfo: Codable, Equatable {
    /// ユーザーID、メールアドレス、ユーザー名
    @Guide(description: "ログイン用のユーザーID、メールアドレス、ユーザー名(例: 'admin', 'user@example.com')")
    public var userID: String?
    
    /// パスワード
    @Guide(description: "ログイン用のパスワード(例: 'password123')")
    public var password: String?
    
    /// ログインページURL
    @Guide(description: "ログインページのURL(例: 'https://example.com/login')")
    public var loginURL: String?
    
    /// サービス名
    @Guide(description: "サービス名やアプリ名(例: 'GitHub', 'AWS Console')")
    public var serviceName: String?
    
    /// 備考
    @Guide(description: "ログインに関する補足情報(例: '2FA有効', '管理者権限')")
    public var note: String?
}
```

##### CardInfo抽出（hasCardInfo = trueの場合）
```swift
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "クレジットカード情報")
public struct CardInfo: Codable, Equatable {
    /// カード番号
    @Guide(description: "クレジットカード番号(例: '1234-5678-9012-3456')")
    public var cardNumber: String?
    
    /// 有効期限
    @Guide(description: "カードの有効期限(例: '12/25', '2025-12')")
    public var expiryDate: String?
    
    /// CVV
    @Guide(description: "カードのセキュリティコード(例: '123')")
    public var cvv: String?
    
    /// カード名義人
    @Guide(description: "カードの名義人(例: 'TARO YAMADA')")
    public var cardholderName: String?
    
    /// カード会社
    @Guide(description: "カード会社名(例: 'VISA', 'MasterCard', 'JCB')")
    public var cardCompany: String?
    
    /// 備考
    @Guide(description: "カードに関する補足情報(例: '海外利用可', '年会費無料')")
    public var note: String?
}
```

##### BankAccountInfo抽出（hasBankAccountInfo = trueの場合）
```swift
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "銀行口座情報")
public struct BankAccountInfo: Codable, Equatable {
    /// 口座番号
    @Guide(description: "銀行口座番号(例: '1234567')")
    public var accountNumber: String?
    
    /// 支店コード
    @Guide(description: "支店コード(例: '001')")
    public var branchCode: String?
    
    /// 銀行名
    @Guide(description: "銀行名(例: '三菱UFJ銀行', 'みずほ銀行')")
    public var bankName: String?
    
    /// 口座種別
    @Guide(description: "口座種別(例: '普通', '当座', '貯蓄')")
    public var accountType: String?
    
    /// 口座名義人
    @Guide(description: "口座名義人(例: 'ヤマダ タロウ')")
    public var accountHolder: String?
    
    /// 備考
    @Guide(description: "口座に関する補足情報(例: 'ネット銀行', 'ATM手数料無料')")
    public var note: String?
}
```

##### ContractInfo抽出（hasContractInfo = trueの場合）
```swift
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "契約情報")
public struct ContractInfo: Codable, Equatable {
    /// 契約者番号
    @Guide(description: "契約者番号や顧客ID(例: 'C123456789')")
    public var contractNumber: String?
    
    /// 契約開始日
    @Guide(description: "契約開始日(例: '2024-01-01', '2024年1月1日')")
    public var startDate: String?
    
    /// 契約終了日
    @Guide(description: "契約終了日(例: '2025-12-31', '2025年12月31日')")
    public var endDate: String?
    
    /// 契約期間
    @Guide(description: "契約期間(例: '1年', '2年間', '無期限')")
    public var contractPeriod: String?
    
    /// 契約プラン
    @Guide(description: "契約プラン名(例: 'ベーシックプラン', 'プレミアムプラン')")
    public var planName: String?
    
    /// 備考
    @Guide(description: "契約に関する補足情報(例: '自動更新', '解約手数料なし')")
    public var note: String?
}
```

##### PlanInfo抽出（hasPlanInfo = trueの場合）
```swift
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "料金プラン情報")
public struct PlanInfo: Codable, Equatable {
    /// プラン名
    @Guide(description: "料金プラン名(例: 'スタンダードプラン', 'プロプラン')")
    public var planName: String?
    
    /// 月額料金
    @Guide(description: "月額料金(例: '980円', '¥1,980')")
    public var monthlyFee: String?
    
    /// 年額料金
    @Guide(description: "年額料金(例: '9,800円', '¥19,800')")
    public var annualFee: String?
    
    /// 更新周期
    @Guide(description: "更新周期(例: '月額', '年額', '無料')")
    public var billingCycle: String?
    
    /// 機能説明
    @Guide(description: "プランの機能説明(例: '基本機能利用可', '全機能利用可')")
    public var features: String?
    
    /// 備考
    @Guide(description: "プランに関する補足情報(例: '初月無料', '学生割引あり')")
    public var note: String?
}
```

##### AccessInfo抽出（hasAccessInfo = trueの場合）
```swift
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "アクセス方法に関する情報")
public struct AccessInfo: Codable, Equatable {
    /// ホスト名
    @Guide(description: "サーバーのホスト名(例: 'server.example.com')")
    public var host: String?
    
    /// IPアドレス
    @Guide(description: "サーバーのIPアドレス(例: '192.168.1.100')")
    public var ip: String?
    
    /// ポート番号
    @Guide(description: "接続ポート番号(例: 22, 80, 443)", .range(1...65535))
    public var port: Int?
    
    /// プロトコル
    @Guide(description: "接続プロトコル(例: 'SSH', 'HTTP', 'HTTPS', 'FTP')")
    public var protocol: String?
    
    /// 接続方法
    @Guide(description: "接続方法の詳細(例: 'SSH鍵認証', 'パスワード認証')")
    public var connectionMethod: String?
    
    /// 備考
    @Guide(description: "アクセスに関する補足情報(例: 'VPN経由', '特定IPからのみ接続可')")
    public var note: String?
}
```

##### ContactInfo抽出（hasContactInfo = trueの場合）
```swift
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "連絡先情報")
public struct ContactInfo: Codable, Equatable {
    /// 住所
    @Guide(description: "住所(例: '東京都渋谷区1-2-3')")
    public var address: String?
    
    /// 電話番号
    @Guide(description: "電話番号(例: '03-1234-5678', '090-1234-5678')")
    public var phoneNumber: String?
    
    /// メールアドレス
    @Guide(description: "メールアドレス(例: 'contact@example.com')")
    public var email: String?
    
    /// 担当者名
    @Guide(description: "担当者名(例: '山田太郎', 'Taro Yamada')")
    public var contactPerson: String?
    
    /// 会社名
    @Guide(description: "会社名や組織名(例: '株式会社サンプル')")
    public var companyName: String?
    
    /// 備考
    @Guide(description: "連絡先に関する補足情報(例: '営業時間: 9:00-18:00', '緊急時のみ連絡')")
    public var note: String?
}
```

### メトリクス設計

#### TwoStepsExtractionMetrics
```swift
public struct TwoStepsExtractionMetrics: Codable, Sendable {
    /// 推定1の処理時間
    public let step1Time: TimeInterval
    /// 推定2の処理時間
    public let step2Time: TimeInterval
    /// 総処理時間
    public let totalTime: TimeInterval
    /// 判定されたカテゴリ数
    public let detectedCategories: Int
    /// 抽出された情報タイプ数
    public let extractedInfoTypes: Int
    /// 推定1の信頼度
    public let step1Confidence: Double
    /// 推定2の信頼度
    public let step2Confidence: Double
    /// 全体の信頼度
    public let overallConfidence: Double
    /// 抽出戦略の効果性
    public let strategyEffectiveness: Double
}
```

### 実装アーキテクチャ

#### UnifiedExtractor拡張
```swift
extension UnifiedExtractor {
    /// 分割推定抽出フロー
    /// @ai[2025-10-21 09:11] 分割推定抽出フローの実装
    /// 目的: ドキュメントタイプ判定と段階的抽出による精度向上
    /// 背景: 単純推定では限界がある複雑なドキュメントへの対応
    /// 意図: より高精度で柔軟な抽出フローを提供
    public func extractByTwoSteps(
        testcase: String,
        level: Int,
        method: ExtractionMethod,
        algo: String,
        language: PromptLanguage
    ) async throws -> (AccountInfo, TwoStepsExtractionMetrics, String, String?) {
        // 推定1: ドキュメントタイプ判定（4段階フロー）
        // 推定2: アカウント情報抽出（4段階フロー）
        // 実装詳細は後述
    }
}
```

#### TwoStepsProcessor
```swift
class TwoStepsProcessor {
    private let log = LogWrapper(subsystem: "com.aitest.twosteps", category: "TwoStepsProcessor")
    private let modelExtractor: ModelExtractor
    
    /// 推定1: ドキュメントタイプ判定（4段階フローで実行）
    func analyzeDocumentType(testData: String, language: PromptLanguage) async throws -> ContentInfo
    
    /// 推定2: 段階的アカウント情報抽出（4段階フローで実行）
    func extractAccountInfoBySteps(
        testData: String, 
        contentInfo: ContentInfo, 
        language: PromptLanguage
    ) async throws -> AccountInfo
}
```

### プロンプトテンプレート設計

#### プロンプトファイル管理方針
- **保存場所**: `Sources/AITest/Prompts/` ディレクトリにファイルとして作成
- **命名規則**: `{step}_{language}_{method}.txt` 形式
  - step: `step1`（推定1）, `step2`（推定2）
  - language: `ja`（日本語）, `en`（英語）
  - method: `generable`（@Generableマクロ使用）, `json`（JSON形式）
- **初期実装**: algoパラメータによらず、統一されたプロンプトを使用

#### 推定1用プロンプトファイル
**ファイル名**: `step1_ja_generable.txt`
```
あなたは文書分析の専門家です。以下の文書を分析し、どのような種類のサービスや情報が含まれているかを判定してください。

文書内容:
{testData}

ContentInfo構造体に従って、以下の情報を抽出してください：
- category: ドキュメントの種類を判定してください(例: 'home', 'creditCard', 'bankCard', 'mobileApps'等)
- hasLoginCredentials: ログインに必要なID、パスワード、URLなどの情報が含まれているか
- hasCardInfo: クレジットカード番号、有効期限、CVVなどのカード情報が含まれているか
- hasBankAccountInfo: 銀行口座番号、支店番号、銀行名などの口座情報が含まれているか
- hasContractInfo: 契約者番号、契約開始日、契約期間などの契約情報が含まれているか
- hasPlanInfo: 料金プラン名、月額料金、更新周期などの料金情報が含まれているか
- hasUrls: ログインページ、公式サイト、サポートページなどのURLが含まれているか
- hasAccessInfo: サーバーのホスト名、ポート番号、IPアドレス、プロトコルなどのアクセス情報が含まれているか
- hasContactInfo: 住所、電話番号、メールアドレスなどの連絡先情報が含まれているか
- confidence: ドキュメントタイプ判定の信頼度（0.0-1.0の範囲）

@Generableマクロを使用してContentInfo構造体として抽出してください。
```

**ファイル名**: `step1_en_generable.txt`
```
You are a document analysis expert. Analyze the following document and determine what types of services and information it contains.

Document content:
{testData}

Extract the following information according to the ContentInfo structure:
- category: Determine the type of document (e.g., 'home', 'creditCard', 'bankCard', 'mobileApps', etc.)
- hasLoginCredentials: Whether it contains login information such as ID, password, URL, etc.
- hasCardInfo: Whether it contains card information such as credit card number, expiry date, CVV, etc.
- hasBankAccountInfo: Whether it contains bank account information such as account number, branch code, bank name, etc.
- hasContractInfo: Whether it contains contract information such as contract number, start date, contract period, etc.
- hasPlanInfo: Whether it contains pricing information such as plan name, monthly fee, billing cycle, etc.
- hasUrls: Whether it contains URLs such as login page, official site, support page, etc.
- hasAccessInfo: Whether it contains access information such as hostname, port number, IP address, protocol, etc.
- hasContactInfo: Whether it contains contact information such as address, phone number, email, etc.
- confidence: Confidence level of document type determination (range 0.0-1.0)

Use @Generable macro to extract as ContentInfo structure.
```

#### 推定2用プロンプトファイル（動的生成）
**ファイル名**: `step2_ja_generable.txt`
```
以下の文書から、{infoType}に関する情報を抽出してください。

文書内容:
{testData}

{generatedStructDescription}

@Generableマクロを使用して{structName}構造体として抽出してください。
```

**ファイル名**: `step2_en_generable.txt`
```
Extract {infoType} information from the following document.

Document content:
{testData}

{generatedStructDescription}

Use @Generable macro to extract as {structName} structure.
```

#### プロンプト読み込み実装
```swift
class TwoStepsPromptLoader {
    private let promptsDirectory = "Sources/AITest/Prompts/"
    
    /// 推定1用プロンプトを読み込み
    func loadStep1Prompt(language: PromptLanguage, method: ExtractionMethod) throws -> String {
        let fileName = "step1_\(language.rawValue)_\(method.rawValue).txt"
        let filePath = promptsDirectory + fileName
        return try String(contentsOfFile: filePath)
    }
    
    /// 推定2用プロンプトを読み込み
    func loadStep2Prompt(language: PromptLanguage, method: ExtractionMethod) throws -> String {
        let fileName = "step2_\(language.rawValue)_\(method.rawValue).txt"
        let filePath = promptsDirectory + fileName
        return try String(contentsOfFile: filePath)
    }
    
    /// プロンプトに変数を置換
    func replaceVariables(in prompt: String, testData: String, infoType: String? = nil, structDescription: String? = nil, structName: String? = nil) -> String {
        var result = prompt.replacingOccurrences(of: "{testData}", with: testData)
        
        if let infoType = infoType {
            result = result.replacingOccurrences(of: "{infoType}", with: infoType)
        }
        
        if let structDescription = structDescription {
            result = result.replacingOccurrences(of: "{generatedStructDescription}", with: structDescription)
        }
        
        if let structName = structName {
            result = result.replacingOccurrences(of: "{structName}", with: structName)
        }
        
        return result
    }
}
```

### エラーハンドリング戦略

#### TwoStepsExtractionError
```swift
public enum TwoStepsExtractionError: LocalizedError {
    case step1Failed(Error)
    case step2Failed(Error)
    case invalidContentInfo
    case noSuitableStrategy
    case extractionTimeout
    case modelInconsistency
}
```

#### フォールバック戦略
1. 推定1が失敗した場合: 基本的なAccountInfo抽出にフォールバック
2. 推定2が失敗した場合: 基本的なAccountInfo抽出にフォールバック
3. 部分的な成功: 抽出できた情報のみを返却

## 実装計画

### Phase 1: 基盤実装
- [ ] ContentCategoryとContentInfoの定義
- [ ] TwoStepsProcessorの基本実装
- [ ] 推定1フローの実装

### Phase 2: 抽出戦略実装
- [ ] 動的構造体生成機能
- [ ] 推定2フローの実装
- [ ] メトリクス収集機能

### Phase 3: 統合とテスト
- [ ] UnifiedExtractorへの統合
- [ ] エラーハンドリングの実装
- [ ] 包括的テストの実装

### Phase 4: 最適化
- [ ] パフォーマンス最適化
- [ ] メモリ効率化
- [ ] プロンプト最適化

## まとめ

分割推定方式は、現在のUnifiedExtractorのアーキテクチャを拡張し、より高精度で柔軟な抽出機能を提供します。各推定は従来通り4段階のフローで構成され、推定1でドキュメントタイプを判定し、推定2で適切な抽出戦略を選択してアカウント情報を抽出します。

この設計により、複雑なドキュメントでも適切な情報を抽出でき、将来的な拡張性も確保されます。
