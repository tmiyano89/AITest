import Foundation
import FoundationModels

/// @ai[2025-10-21 13:10] ログイン認証情報構造体
/// 目的: ログイン関連の情報を抽出するための専用構造体
/// 背景: 分割推定方式の推定2でhasLoginCredentials=trueの場合に使用
/// 意図: ログイン情報を構造化して抽出し、後でAccountInfoにマッピング
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "ログイン認証情報")
public struct LoginCredentialsInfo: Codable, Equatable, Sendable {
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

    public init(
        userID: String? = nil,
        password: String? = nil,
        loginURL: String? = nil,
        serviceName: String? = nil,
        note: String? = nil
    ) {
        self.userID = userID
        self.password = password
        self.loginURL = loginURL
        self.serviceName = serviceName
        self.note = note
    }
}

/// @ai[2025-10-21 13:10] クレジットカード情報構造体
/// 目的: クレジットカード関連の情報を抽出するための専用構造体
/// 背景: 分割推定方式の推定2でhasCardInfo=trueの場合に使用
/// 意図: カード情報を構造化して抽出し、後でAccountInfoのnoteフィールドにマッピング
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "クレジットカード情報")
public struct CardInfo: Codable, Equatable, Sendable {
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

    public init(
        cardNumber: String? = nil,
        expiryDate: String? = nil,
        cvv: String? = nil,
        cardholderName: String? = nil,
        cardCompany: String? = nil,
        note: String? = nil
    ) {
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.cvv = cvv
        self.cardholderName = cardholderName
        self.cardCompany = cardCompany
        self.note = note
    }
}

/// @ai[2025-10-21 13:10] 銀行口座情報構造体
/// 目的: 銀行口座関連の情報を抽出するための専用構造体
/// 背景: 分割推定方式の推定2でhasBankAccountInfo=trueの場合に使用
/// 意図: 口座情報を構造化して抽出し、後でAccountInfoのnoteフィールドにマッピング
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "銀行口座情報")
public struct BankAccountInfo: Codable, Equatable, Sendable {
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

    public init(
        accountNumber: String? = nil,
        branchCode: String? = nil,
        bankName: String? = nil,
        accountType: String? = nil,
        accountHolder: String? = nil,
        note: String? = nil
    ) {
        self.accountNumber = accountNumber
        self.branchCode = branchCode
        self.bankName = bankName
        self.accountType = accountType
        self.accountHolder = accountHolder
        self.note = note
    }
}

/// @ai[2025-10-21 13:10] 契約情報構造体
/// 目的: 契約関連の情報を抽出するための専用構造体
/// 背景: 分割推定方式の推定2でhasContractInfo=trueの場合に使用
/// 意図: 契約情報を構造化して抽出し、後でAccountInfoのnoteフィールドにマッピング
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "契約情報")
public struct ContractInfo: Codable, Equatable, Sendable {
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

    public init(
        contractNumber: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        contractPeriod: String? = nil,
        planName: String? = nil,
        note: String? = nil
    ) {
        self.contractNumber = contractNumber
        self.startDate = startDate
        self.endDate = endDate
        self.contractPeriod = contractPeriod
        self.planName = planName
        self.note = note
    }
}

/// @ai[2025-10-21 13:10] 料金プラン情報構造体
/// 目的: 料金プラン関連の情報を抽出するための専用構造体
/// 背景: 分割推定方式の推定2でhasPlanInfo=trueの場合に使用
/// 意図: プラン情報を構造化して抽出し、後でAccountInfoのnoteフィールドにマッピング
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "料金プラン情報")
public struct PlanInfo: Codable, Equatable, Sendable {
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

    public init(
        planName: String? = nil,
        monthlyFee: String? = nil,
        annualFee: String? = nil,
        billingCycle: String? = nil,
        features: String? = nil,
        note: String? = nil
    ) {
        self.planName = planName
        self.monthlyFee = monthlyFee
        self.annualFee = annualFee
        self.billingCycle = billingCycle
        self.features = features
        self.note = note
    }
}

/// @ai[2025-10-21 13:10] アクセス方法情報構造体
/// 目的: アクセス方法関連の情報を抽出するための専用構造体
/// 背景: 分割推定方式の推定2でhasAccessInfo=trueの場合に使用
/// 意図: アクセス情報を構造化して抽出し、後でAccountInfoのhost/portフィールドにマッピング
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "アクセス方法に関する情報")
public struct AccessInfo: Codable, Equatable, Sendable {
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
    public var connectionProtocol: String?

    /// 接続方法
    @Guide(description: "接続方法の詳細(例: 'SSH鍵認証', 'パスワード認証')")
    public var connectionMethod: String?

    /// 備考
    @Guide(description: "アクセスに関する補足情報(例: 'VPN経由', '特定IPからのみ接続可')")
    public var note: String?

    public init(
        host: String? = nil,
        ip: String? = nil,
        port: Int? = nil,
        connectionProtocol: String? = nil,
        connectionMethod: String? = nil,
        note: String? = nil
    ) {
        self.host = host
        self.ip = ip
        self.port = port
        self.connectionProtocol = connectionProtocol
        self.connectionMethod = connectionMethod
        self.note = note
    }
}

/// @ai[2025-10-21 13:10] 連絡先情報構造体
/// 目的: 連絡先関連の情報を抽出するための専用構造体
/// 背景: 分割推定方式の推定2でhasContactInfo=trueの場合に使用
/// 意図: 連絡先情報を構造化して抽出し、後でAccountInfoのnoteフィールドにマッピング
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "連絡先情報")
public struct ContactInfo: Codable, Equatable, Sendable {
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

    public init(
        address: String? = nil,
        phoneNumber: String? = nil,
        email: String? = nil,
        contactPerson: String? = nil,
        companyName: String? = nil,
        note: String? = nil
    ) {
        self.address = address
        self.phoneNumber = phoneNumber
        self.email = email
        self.contactPerson = contactPerson
        self.companyName = companyName
        self.note = note
    }
}
