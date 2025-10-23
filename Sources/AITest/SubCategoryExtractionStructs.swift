import Foundation
import FoundationModels

/// @ai[2025-10-21 16:00] サブカテゴリ別抽出構造体
/// 目的: 各サブカテゴリに特化した情報抽出構造体を定義
/// 背景: サブカテゴリごとに一般的に管理すべき情報が異なる
/// 意図: より精密で実用的な情報抽出を実現

// MARK: - Personal Subcategories

/// @ai[2025-10-21 16:00] 個人生活 - 自宅・公共料金
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "自宅・公共料金に関する情報")
public struct PersonalHomeInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: '自宅', '東京電力'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "住所（例: '東京都渋谷区1-2-3'）")
    public var address: String?

    @Guide(description: "電気契約の顧客番号・お客様番号")
    public var electricityAccount: String?

    @Guide(description: "ガス契約の顧客番号・お客様番号")
    public var gasAccount: String?

    @Guide(description: "水道契約の顧客番号・お客様番号")
    public var waterAccount: String?

    @Guide(description: "インターネットプロバイダ名・契約番号")
    public var internetProvider: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        address: String? = nil,
        electricityAccount: String? = nil,
        gasAccount: String? = nil,
        waterAccount: String? = nil,
        internetProvider: String? = nil
    ) {
        self.title = title
        self.note = note
        self.address = address
        self.electricityAccount = electricityAccount
        self.gasAccount = gasAccount
        self.waterAccount = waterAccount
        self.internetProvider = internetProvider
    }
}

/// @ai[2025-10-21 16:00] 個人生活 - 学校・習い事
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "学校・習い事に関する情報")
public struct PersonalEducationInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: '東京大学', '英会話スクール ABC'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "学校名・スクール名")
    public var schoolName: String?

    @Guide(description: "学籍番号・生徒ID")
    public var studentID: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "学費・授業料情報")
    public var tuitionInfo: String?

    @Guide(description: "奨学金・支援制度情報")
    public var scholarshipInfo: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        schoolName: String? = nil,
        studentID: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        tuitionInfo: String? = nil,
        scholarshipInfo: String? = nil
    ) {
        self.title = title
        self.note = note
        self.schoolName = schoolName
        self.studentID = studentID
        self.userID = userID
        self.password = password
        self.tuitionInfo = tuitionInfo
        self.scholarshipInfo = scholarshipInfo
    }
}

/// @ai[2025-10-21 16:00] 個人生活 - 病院・医療
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "病院・医療に関する情報")
public struct PersonalHealthInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: '山田クリニック', '健康管理アプリ'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "病院名・クリニック名")
    public var hospitalName: String?

    @Guide(description: "患者ID・診察券番号")
    public var patientID: String?

    @Guide(description: "保険証番号")
    public var insuranceNumber: String?

    @Guide(description: "担当医師名")
    public var doctorName: String?

    @Guide(description: "ログインID・ユーザーID（オンライン予約等）")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        hospitalName: String? = nil,
        patientID: String? = nil,
        insuranceNumber: String? = nil,
        doctorName: String? = nil,
        userID: String? = nil,
        password: String? = nil
    ) {
        self.title = title
        self.note = note
        self.hospitalName = hospitalName
        self.patientID = patientID
        self.insuranceNumber = insuranceNumber
        self.doctorName = doctorName
        self.userID = userID
        self.password = password
    }
}

/// @ai[2025-10-21 16:00] 個人生活 - 連絡先・知人
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "連絡先・知人に関する情報")
public struct PersonalContactsInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・名前（例: '山田太郎', '緊急連絡先'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "氏名")
    public var name: String?

    @Guide(description: "電話番号")
    public var phoneNumber: String?

    @Guide(description: "メールアドレス")
    public var email: String?

    @Guide(description: "住所")
    public var address: String?

    @Guide(description: "続柄・関係性（例: '友人', '家族', '同僚'）")
    public var relationship: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        name: String? = nil,
        phoneNumber: String? = nil,
        email: String? = nil,
        address: String? = nil,
        relationship: String? = nil
    ) {
        self.title = title
        self.note = note
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.address = address
        self.relationship = relationship
    }
}

/// @ai[2025-10-21 16:00] 個人生活 - その他個人
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "その他個人生活に関する情報")
public struct PersonalOtherInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス・項目の説明")
    public var description: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "URL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        description: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.description = description
        self.userID = userID
        self.password = password
        self.url = url
    }
}

// MARK: - Financial Subcategories

/// @ai[2025-10-21 16:00] 金融・決済 - 銀行・証券
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "銀行・証券に関する情報")
public struct FinancialBankingInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・金融機関名（例: '三菱UFJ銀行', 'SBI証券'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "銀行名・証券会社名")
    public var bankName: String?

    @Guide(description: "支店名")
    public var branchName: String?

    @Guide(description: "口座番号")
    public var accountNumber: String?

    @Guide(description: "口座種別（例: '普通', '当座', '貯蓄'）")
    public var accountType: String?

    @Guide(description: "オンラインバンキングID・ログインID")
    public var userID: String?

    @Guide(description: "パスワード・暗証番号")
    public var password: String?

    @Guide(description: "オンラインバンキングURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        bankName: String? = nil,
        branchName: String? = nil,
        accountNumber: String? = nil,
        accountType: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.bankName = bankName
        self.branchName = branchName
        self.accountNumber = accountNumber
        self.accountType = accountType
        self.userID = userID
        self.password = password
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] 金融・決済 - クレジットカード
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "クレジットカードに関する情報")
public struct FinancialCreditCardInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・カード名（例: '楽天カード', '三井住友VISAカード'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "カード番号")
    public var cardNumber: String?

    @Guide(description: "カード名義人")
    public var cardholderName: String?

    @Guide(description: "有効期限")
    public var expiryDate: String?

    @Guide(description: "セキュリティコード・CVV")
    public var cvv: String?

    @Guide(description: "カード会社名")
    public var cardCompany: String?

    @Guide(description: "カード種別（例: 'VISA', 'MasterCard', 'JCB'）")
    public var cardType: String?

    @Guide(description: "会員サイトのログインID")
    public var userID: String?

    @Guide(description: "会員サイトのパスワード")
    public var password: String?

    @Guide(description: "会員サイトURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        cardNumber: String? = nil,
        cardholderName: String? = nil,
        expiryDate: String? = nil,
        cvv: String? = nil,
        cardCompany: String? = nil,
        cardType: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.cardNumber = cardNumber
        self.cardholderName = cardholderName
        self.expiryDate = expiryDate
        self.cvv = cvv
        self.cardCompany = cardCompany
        self.cardType = cardType
        self.userID = userID
        self.password = password
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] 金融・決済 - 決済サービス
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "決済サービスに関する情報")
public struct FinancialPaymentInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: 'PayPay', 'Suica'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス名")
    public var serviceName: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "連携カード情報")
    public var linkedCard: String?

    @Guide(description: "残高・ポイント")
    public var balance: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serviceName: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        linkedCard: String? = nil,
        balance: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serviceName = serviceName
        self.userID = userID
        self.password = password
        self.linkedCard = linkedCard
        self.balance = balance
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] 金融・決済 - 保険・年金
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "保険・年金に関する情報")
public struct FinancialInsuranceInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・保険名（例: '生命保険', '自動車保険'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "保険会社名")
    public var insuranceCompany: String?

    @Guide(description: "証券番号・契約番号")
    public var policyNumber: String?

    @Guide(description: "保険種別（例: '生命保険', '医療保険', '自動車保険'）")
    public var policyType: String?

    @Guide(description: "保険料")
    public var premium: String?

    @Guide(description: "受取人")
    public var beneficiary: String?

    @Guide(description: "会員サイトのログインID")
    public var userID: String?

    @Guide(description: "会員サイトのパスワード")
    public var password: String?

    @Guide(description: "会員サイトURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        insuranceCompany: String? = nil,
        policyNumber: String? = nil,
        policyType: String? = nil,
        premium: String? = nil,
        beneficiary: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.insuranceCompany = insuranceCompany
        self.policyNumber = policyNumber
        self.policyType = policyType
        self.premium = premium
        self.beneficiary = beneficiary
        self.userID = userID
        self.password = password
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] 金融・決済 - 仮想通貨
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "仮想通貨に関する情報")
public struct FinancialCryptoInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・取引所名（例: 'Coinbase', 'bitFlyer'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "取引所名・サービス名")
    public var exchangeName: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "ウォレットアドレス")
    public var walletAddress: String?

    @Guide(description: "APIキー")
    public var apiKey: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        exchangeName: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        walletAddress: String? = nil,
        apiKey: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.exchangeName = exchangeName
        self.userID = userID
        self.password = password
        self.walletAddress = walletAddress
        self.apiKey = apiKey
        self.url = url
    }
}

// MARK: - Digital Subcategories

/// @ai[2025-10-21 16:00] デジタルサービス - サブスク
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "サブスクリプションサービスに関する情報")
public struct DigitalSubscriptionInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: 'Netflix', 'Spotify'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス名")
    public var serviceName: String?

    @Guide(description: "プラン名")
    public var planName: String?

    @Guide(description: "月額料金")
    public var monthlyFee: String?

    @Guide(description: "更新日")
    public var renewalDate: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serviceName: String? = nil,
        planName: String? = nil,
        monthlyFee: String? = nil,
        renewalDate: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serviceName = serviceName
        self.planName = planName
        self.monthlyFee = monthlyFee
        self.renewalDate = renewalDate
        self.userID = userID
        self.password = password
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] デジタルサービス - AIサービス
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "AIサービスに関する情報")
public struct DigitalAIInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: 'OpenAI', 'Claude API'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス名")
    public var serviceName: String?

    @Guide(description: "APIキー")
    public var apiKey: String?

    @Guide(description: "APIエンドポイント・URL")
    public var apiEndpoint: String?

    @Guide(description: "プラン名")
    public var planName: String?

    @Guide(description: "月額料金")
    public var monthlyFee: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serviceName: String? = nil,
        apiKey: String? = nil,
        apiEndpoint: String? = nil,
        planName: String? = nil,
        monthlyFee: String? = nil,
        userID: String? = nil,
        password: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serviceName = serviceName
        self.apiKey = apiKey
        self.apiEndpoint = apiEndpoint
        self.planName = planName
        self.monthlyFee = monthlyFee
        self.userID = userID
        self.password = password
    }
}

/// @ai[2025-10-21 16:00] デジタルサービス - SNS
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "SNSに関する情報")
public struct DigitalSocialInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・プラットフォーム名（例: 'Twitter', 'Facebook'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "プラットフォーム名")
    public var platformName: String?

    @Guide(description: "ユーザー名")
    public var username: String?

    @Guide(description: "メールアドレス")
    public var email: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "プロフィールURL")
    public var profileURL: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        platformName: String? = nil,
        username: String? = nil,
        email: String? = nil,
        password: String? = nil,
        profileURL: String? = nil
    ) {
        self.title = title
        self.note = note
        self.platformName = platformName
        self.username = username
        self.email = email
        self.password = password
        self.profileURL = profileURL
    }
}

/// @ai[2025-10-21 16:00] デジタルサービス - EC・ショッピング
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "EC・ショッピングサイトに関する情報")
public struct DigitalShoppingInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サイト名（例: 'Amazon', '楽天市場'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サイト名")
    public var siteName: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "メールアドレス")
    public var email: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "会員ランク・レベル")
    public var membershipLevel: String?

    @Guide(description: "ポイント残高")
    public var points: String?

    @Guide(description: "サイトURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        siteName: String? = nil,
        userID: String? = nil,
        email: String? = nil,
        password: String? = nil,
        membershipLevel: String? = nil,
        points: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.siteName = siteName
        self.userID = userID
        self.email = email
        self.password = password
        self.membershipLevel = membershipLevel
        self.points = points
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] デジタルサービス - アプリ・ゲーム
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "アプリ・ゲームに関する情報")
public struct DigitalAppsInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・アプリ名（例: 'Steam', 'PlayStation Network'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "アプリ名・ゲーム名")
    public var appName: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "メールアドレス")
    public var email: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "サブスクリプション種別")
    public var subscriptionType: String?

    @Guide(description: "デバイス情報")
    public var deviceInfo: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        appName: String? = nil,
        userID: String? = nil,
        email: String? = nil,
        password: String? = nil,
        subscriptionType: String? = nil,
        deviceInfo: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.appName = appName
        self.userID = userID
        self.email = email
        self.password = password
        self.subscriptionType = subscriptionType
        self.deviceInfo = deviceInfo
        self.url = url
    }
}

// MARK: - Work Subcategories

/// @ai[2025-10-21 16:00] 仕事・ビジネス - サーバー・VPS
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "サーバー・VPSに関する情報")
public struct WorkServerInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サーバー名（例: 'AWS EC2', 'Sakura VPS'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サーバー名")
    public var serverName: String?

    @Guide(description: "ホスト名・IPアドレス")
    public var host: String?

    @Guide(description: "ポート番号", .range(1...65535))
    public var port: Int?

    @Guide(description: "ログインID・ユーザー名")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "SSH秘密鍵")
    public var sshKey: String?

    @Guide(description: "接続プロトコル（例: 'SSH', 'RDP', 'HTTPS'）")
    public var connectionProtocol: String?

    @Guide(description: "管理画面URL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serverName: String? = nil,
        host: String? = nil,
        port: Int? = nil,
        userID: String? = nil,
        password: String? = nil,
        sshKey: String? = nil,
        connectionProtocol: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serverName = serverName
        self.host = host
        self.port = port
        self.userID = userID
        self.password = password
        self.sshKey = sshKey
        self.connectionProtocol = connectionProtocol
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] 仕事・ビジネス - 業務SaaS
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "業務SaaSに関する情報")
public struct WorkSaaSInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: 'Slack', 'Notion'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス名")
    public var serviceName: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "メールアドレス")
    public var email: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "プラン名")
    public var planName: String?

    @Guide(description: "チーム情報・ワークスペース名")
    public var teamInfo: String?

    @Guide(description: "APIキー")
    public var apiKey: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serviceName: String? = nil,
        userID: String? = nil,
        email: String? = nil,
        password: String? = nil,
        planName: String? = nil,
        teamInfo: String? = nil,
        apiKey: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serviceName = serviceName
        self.userID = userID
        self.email = email
        self.password = password
        self.planName = planName
        self.teamInfo = teamInfo
        self.apiKey = apiKey
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] 仕事・ビジネス - 開発ツール
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "開発ツールに関する情報")
public struct WorkDevelopmentInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: 'GitHub', 'GitLab'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス名")
    public var serviceName: String?

    @Guide(description: "ユーザー名")
    public var username: String?

    @Guide(description: "メールアドレス")
    public var email: String?

    @Guide(description: "アクセストークン・パーソナルアクセストークン")
    public var accessToken: String?

    @Guide(description: "リポジトリURL")
    public var repositoryURL: String?

    @Guide(description: "APIキー")
    public var apiKey: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serviceName: String? = nil,
        username: String? = nil,
        email: String? = nil,
        accessToken: String? = nil,
        repositoryURL: String? = nil,
        apiKey: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serviceName = serviceName
        self.username = username
        self.email = email
        self.accessToken = accessToken
        self.repositoryURL = repositoryURL
        self.apiKey = apiKey
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] 仕事・ビジネス - ビジネスコミュニケーション
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "ビジネスコミュニケーションツールに関する情報")
public struct WorkCommunicationInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: 'Zoom', 'Google Meet'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス名")
    public var serviceName: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "メールアドレス")
    public var email: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "ミーティングID・ルームID")
    public var meetingID: String?

    @Guide(description: "会議室URL")
    public var roomURL: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serviceName: String? = nil,
        userID: String? = nil,
        email: String? = nil,
        password: String? = nil,
        meetingID: String? = nil,
        roomURL: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serviceName = serviceName
        self.userID = userID
        self.email = email
        self.password = password
        self.meetingID = meetingID
        self.roomURL = roomURL
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] 仕事・ビジネス - その他業務
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "その他業務関連サービスに関する情報")
public struct WorkOtherInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス名")
    public var serviceName: String?

    @Guide(description: "サービス説明")
    public var description: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serviceName: String? = nil,
        description: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serviceName = serviceName
        self.description = description
        self.userID = userID
        self.password = password
        self.url = url
    }
}

// MARK: - Infrastructure Subcategories

/// @ai[2025-10-21 16:00] インフラ・公的 - 携帯・通信
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "携帯・通信に関する情報")
public struct InfraTelecomInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・キャリア名（例: 'docomo', 'au'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "キャリア名・プロバイダ名")
    public var carrierName: String?

    @Guide(description: "電話番号")
    public var phoneNumber: String?

    @Guide(description: "契約番号・お客様番号")
    public var contractNumber: String?

    @Guide(description: "プラン名")
    public var planName: String?

    @Guide(description: "月額料金")
    public var monthlyFee: String?

    @Guide(description: "SIM番号・ICCID")
    public var simNumber: String?

    @Guide(description: "マイページURL")
    public var url: String?

    @Guide(description: "マイページのログインID")
    public var userID: String?

    @Guide(description: "マイページのパスワード")
    public var password: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        carrierName: String? = nil,
        phoneNumber: String? = nil,
        contractNumber: String? = nil,
        planName: String? = nil,
        monthlyFee: String? = nil,
        simNumber: String? = nil,
        url: String? = nil,
        userID: String? = nil,
        password: String? = nil
    ) {
        self.title = title
        self.note = note
        self.carrierName = carrierName
        self.phoneNumber = phoneNumber
        self.contractNumber = contractNumber
        self.planName = planName
        self.monthlyFee = monthlyFee
        self.simNumber = simNumber
        self.url = url
        self.userID = userID
        self.password = password
    }
}

/// @ai[2025-10-21 16:00] インフラ・公的 - 公共料金
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "公共料金に関する情報")
public struct InfraUtilitiesInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・会社名（例: '東京電力', '東京ガス'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "公共料金種別（例: '電気', 'ガス', '水道'）")
    public var utilityType: String?

    @Guide(description: "お客様番号・契約番号")
    public var accountNumber: String?

    @Guide(description: "需要家番号")
    public var customerNumber: String?

    @Guide(description: "契約住所")
    public var contractAddress: String?

    @Guide(description: "月額料金目安")
    public var monthlyFee: String?

    @Guide(description: "マイページURL")
    public var url: String?

    @Guide(description: "マイページのログインID")
    public var userID: String?

    @Guide(description: "マイページのパスワード")
    public var password: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        utilityType: String? = nil,
        accountNumber: String? = nil,
        customerNumber: String? = nil,
        contractAddress: String? = nil,
        monthlyFee: String? = nil,
        url: String? = nil,
        userID: String? = nil,
        password: String? = nil
    ) {
        self.title = title
        self.note = note
        self.utilityType = utilityType
        self.accountNumber = accountNumber
        self.customerNumber = customerNumber
        self.contractAddress = contractAddress
        self.monthlyFee = monthlyFee
        self.url = url
        self.userID = userID
        self.password = password
    }
}

/// @ai[2025-10-21 16:00] インフラ・公的 - 行政サービス
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "行政サービスに関する情報")
public struct InfraGovernmentInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: 'マイナポータル', 'e-Tax'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス名")
    public var serviceName: String?

    @Guide(description: "ログインID・利用者ID")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "マイナンバーカード情報")
    public var mynumberCardInfo: String?

    @Guide(description: "手続き情報・申請内容")
    public var procedureInfo: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serviceName: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        mynumberCardInfo: String? = nil,
        procedureInfo: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serviceName = serviceName
        self.userID = userID
        self.password = password
        self.mynumberCardInfo = mynumberCardInfo
        self.procedureInfo = procedureInfo
        self.url = url
    }
}

/// @ai[2025-10-21 16:00] インフラ・公的 - 免許・資格
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "免許・資格に関する情報")
public struct InfraLicenseInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・免許/資格名（例: '運転免許証', '応用情報技術者'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "免許・資格種別")
    public var licenseType: String?

    @Guide(description: "免許・資格番号")
    public var licenseNumber: String?

    @Guide(description: "発行日")
    public var issueDate: String?

    @Guide(description: "有効期限")
    public var expiryDate: String?

    @Guide(description: "発行機関")
    public var issuingAuthority: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        licenseType: String? = nil,
        licenseNumber: String? = nil,
        issueDate: String? = nil,
        expiryDate: String? = nil,
        issuingAuthority: String? = nil
    ) {
        self.title = title
        self.note = note
        self.licenseType = licenseType
        self.licenseNumber = licenseNumber
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.issuingAuthority = issuingAuthority
    }
}

/// @ai[2025-10-21 16:00] インフラ・公的 - 交通・移動
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "交通・移動に関する情報")
public struct InfraTransportationInfo: Codable, Equatable, Sendable {
    @Guide(description: "タイトル・サービス名（例: 'Suica', 'Uber'）")
    public var title: String?

    @Guide(description: "備考・補足情報")
    public var note: String?

    @Guide(description: "サービス名")
    public var serviceName: String?

    @Guide(description: "カード番号・会員番号")
    public var cardNumber: String?

    @Guide(description: "ログインID・ユーザーID")
    public var userID: String?

    @Guide(description: "パスワード")
    public var password: String?

    @Guide(description: "残高")
    public var balance: String?

    @Guide(description: "オートチャージ設定")
    public var autoCharge: String?

    @Guide(description: "サービスURL")
    public var url: String?

    public init(
        title: String? = nil,
        note: String? = nil,
        serviceName: String? = nil,
        cardNumber: String? = nil,
        userID: String? = nil,
        password: String? = nil,
        balance: String? = nil,
        autoCharge: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.note = note
        self.serviceName = serviceName
        self.cardNumber = cardNumber
        self.userID = userID
        self.password = password
        self.balance = balance
        self.autoCharge = autoCharge
        self.url = url
    }
}
