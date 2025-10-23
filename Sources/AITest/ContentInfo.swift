import Foundation
import FoundationModels

/// @ai[2025-10-21 15:00] メインカテゴリ定義（第1層）
/// 目的: ドキュメントの大分類を定義
/// 背景: 2層構造でAIの判定精度を向上
/// 意図: まず5つのメインカテゴリに分類し、その後サブカテゴリを判定
@available(iOS 26.0, macOS 26.0, *)
public enum MainCategory: String, Codable, CaseIterable, Sendable {
    case personal       // 個人生活（自宅、教育、医療、連絡先等）
    case financial      // 金融・決済（銀行、カード、保険、決済等）
    case digital        // デジタルサービス（サブスク、AI、SNS、EC等）
    case work           // 仕事・ビジネス（サーバー、SaaS、開発ツール等）
    case infrastructure // インフラ・公的（通信、公共料金、行政、免許等）

    public var displayName: String {
        switch self {
        case .personal: return "個人生活"
        case .financial: return "金融・決済"
        case .digital: return "デジタルサービス"
        case .work: return "仕事・ビジネス"
        case .infrastructure: return "インフラ・公的"
        }
    }
}

/// @ai[2025-10-21 15:00] サブカテゴリ定義（第2層）
/// 目的: メインカテゴリ配下の詳細分類を定義
/// 背景: 各メインカテゴリに5つのサブカテゴリを定義（5×5=25項目）
/// 意図: より詳細で正確なカテゴリ分類を実現
@available(iOS 26.0, macOS 26.0, *)
public enum SubCategory: String, Codable, Sendable, CaseIterable {
    // personal配下（5項目）
    case personalHome           // 自宅・公共料金・家電
    case personalEducation      // 学校・習い事・資格勉強
    case personalHealth         // 病院・医療・健康管理
    case personalContacts       // 連絡先・友人・知人
    case personalOther          // その他個人生活

    // financial配下（5項目）
    case financialBanking       // 銀行・証券・投資
    case financialCreditCard    // クレジットカード
    case financialPayment       // 決済サービス・電子マネー
    case financialInsurance     // 保険・年金
    case financialCrypto        // 仮想通貨・ブロックチェーン

    // digital配下（5項目）
    case digitalSubscription    // 動画・音楽サブスク
    case digitalAI              // AIサービス・AI API
    case digitalSocial          // SNS・コミュニティ
    case digitalShopping        // EC・ショッピング
    case digitalApps            // モバイルアプリ・ゲーム

    // work配下（5項目）
    case workServer             // サーバー・VPS・クラウド
    case workSaaS               // 業務SaaS・ツール
    case workDevelopment        // 開発ツール・API
    case workCommunication      // ビジネスコミュニケーション
    case workOther              // その他業務関連

    // infrastructure配下（5項目）
    case infraTelecom           // 携帯・光回線・ISP
    case infraUtilities         // 電気・ガス・水道
    case infraGovernment        // 行政・公的サービス
    case infraLicense           // 免許・資格・証明書
    case infraTransportation    // 交通・移動・旅行

    public var displayName: String {
        switch self {
        // personal
        case .personalHome: return "自宅・公共料金"
        case .personalEducation: return "学校・習い事"
        case .personalHealth: return "病院・医療"
        case .personalContacts: return "連絡先・知人"
        case .personalOther: return "その他個人"
        // financial
        case .financialBanking: return "銀行・証券"
        case .financialCreditCard: return "クレジットカード"
        case .financialPayment: return "決済サービス"
        case .financialInsurance: return "保険・年金"
        case .financialCrypto: return "仮想通貨"
        // digital
        case .digitalSubscription: return "サブスク"
        case .digitalAI: return "AIサービス"
        case .digitalSocial: return "SNS"
        case .digitalShopping: return "EC・ショッピング"
        case .digitalApps: return "アプリ・ゲーム"
        // work
        case .workServer: return "サーバー・VPS"
        case .workSaaS: return "業務SaaS"
        case .workDevelopment: return "開発ツール"
        case .workCommunication: return "ビジネスコミュニケーション"
        case .workOther: return "その他業務"
        // infrastructure
        case .infraTelecom: return "携帯・通信"
        case .infraUtilities: return "公共料金"
        case .infraGovernment: return "行政サービス"
        case .infraLicense: return "免許・資格"
        case .infraTransportation: return "交通・移動"
        }
    }

    /// サブカテゴリが属するメインカテゴリを返す
    public var mainCategory: MainCategory {
        switch self {
        case .personalHome, .personalEducation, .personalHealth, .personalContacts, .personalOther:
            return .personal
        case .financialBanking, .financialCreditCard, .financialPayment, .financialInsurance, .financialCrypto:
            return .financial
        case .digitalSubscription, .digitalAI, .digitalSocial, .digitalShopping, .digitalApps:
            return .digital
        case .workServer, .workSaaS, .workDevelopment, .workCommunication, .workOther:
            return .work
        case .infraTelecom, .infraUtilities, .infraGovernment, .infraLicense, .infraTransportation:
            return .infrastructure
        }
    }
}

/// @ai[2025-10-21 15:00] メインカテゴリに対応するサブカテゴリを取得
@available(iOS 26.0, macOS 26.0, *)
extension MainCategory {
    /// このメインカテゴリに属するサブカテゴリの配列を返す
    public var subCategories: [SubCategory] {
        switch self {
        case .personal:
            return [.personalHome, .personalEducation, .personalHealth, .personalContacts, .personalOther]
        case .financial:
            return [.financialBanking, .financialCreditCard, .financialPayment, .financialInsurance, .financialCrypto]
        case .digital:
            return [.digitalSubscription, .digitalAI, .digitalSocial, .digitalShopping, .digitalApps]
        case .work:
            return [.workServer, .workSaaS, .workDevelopment, .workCommunication, .workOther]
        case .infrastructure:
            return [.infraTelecom, .infraUtilities, .infraGovernment, .infraLicense, .infraTransportation]
        }
    }
}

/// @ai[2025-10-21 15:10] メインカテゴリ情報構造体
/// @ai[2025-10-22 20:00] confidence削除（信頼性評価は不要）
/// @ai[2025-10-22 20:30] @Generableマクロ追加（FoundationModels構造化出力用）
/// 目的: 第1段階のメインカテゴリ判定結果を格納
/// 背景: 2層判定の第1段階で使用
/// 意図: 5つのメインカテゴリから1つを判定
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "メインカテゴリ判定結果")
public struct MainCategoryInfo: Codable, Equatable, Sendable {
    /// メインカテゴリ（文字列形式）
    @Guide(description: "メインカテゴリ（personal, financial, digital, work, infrastructure のいずれか1つ）")
    public var mainCategory: String

    /// メインカテゴリをenumとして取得
    public var mainCategoryEnum: MainCategory {
        MainCategory(rawValue: mainCategory) ?? .personal
    }

    public init(mainCategory: String) {
        self.mainCategory = mainCategory
    }
}

/// @ai[2025-10-21 15:10] サブカテゴリ情報構造体
/// @ai[2025-10-22 20:00] confidence削除（信頼性評価は不要）
/// @ai[2025-10-22 20:30] @Generableマクロ追加（FoundationModels構造化出力用）
/// 目的: 第2段階のサブカテゴリ判定結果を格納
/// 背景: 2層判定の第2段階で使用
/// 意図: メインカテゴリ配下の5つのサブカテゴリから1つを判定
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "サブカテゴリ判定結果")
public struct SubCategoryInfo: Codable, Equatable, Sendable {
    /// サブカテゴリ（文字列形式）
    @Guide(description: "サブカテゴリ（メインカテゴリに応じた5つの選択肢から1つ）")
    public var subCategory: String

    /// サブカテゴリをenumとして取得
    public var subCategoryEnum: SubCategory? {
        SubCategory(rawValue: subCategory)
    }

    public init(subCategory: String) {
        self.subCategory = subCategory
    }
}

/// @ai[2025-10-21 13:00] コンテンツ情報構造体
/// @ai[2025-10-21 15:10] 2層カテゴリ構造に対応
/// @ai[2025-10-22 18:45] has*フィールドを削除（分割推定方式では不要）
/// @ai[2025-10-22 20:00] confidence削除（信頼性評価は不要）
/// @ai[2025-10-22 20:30] 文字列フィールドに統一（enum取得は計算プロパティで）
/// 目的: ドキュメントのカテゴリ判定結果を格納
/// 背景: 分割推定方式の推定1（カテゴリ判定）で使用
/// 意図: サブカテゴリ判定により、専用構造体とマッピングルールからAccountInfoを構築
@available(iOS 26.0, macOS 26.0, *)
public struct ContentInfo: Codable, Equatable, Sendable {
    /// メインカテゴリ（文字列形式）
    public var mainCategory: String

    /// サブカテゴリ（文字列形式）
    public var subCategory: String

    /// メインカテゴリをenumとして取得
    public var mainCategoryEnum: MainCategory {
        MainCategory(rawValue: mainCategory) ?? .personal
    }

    /// サブカテゴリをenumとして取得
    public var subCategoryEnum: SubCategory? {
        SubCategory(rawValue: subCategory)
    }

    public init(
        mainCategory: String,
        subCategory: String
    ) {
        self.mainCategory = mainCategory
        self.subCategory = subCategory
    }
}
