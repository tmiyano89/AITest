import Foundation
import FoundationModels


/// @ai[2025-10-21 15:10] メインカテゴリ情報構造体
/// @ai[2025-10-22 20:00] confidence削除（信頼性評価は不要）
/// @ai[2025-11-05 17:00] @Generableマクロ削除（TwoSteps抽出はJSON方式のみ）
/// 目的: 第1段階のメインカテゴリ判定結果を格納（JSON抽出用）
/// 背景: 2層判定の第1段階で使用、@GenerableはOne-step抽出専用
/// 意図: 5つのメインカテゴリから1つを判定（JSON形式）
@available(iOS 26.0, macOS 26.0, *)
public struct MainCategoryInfo: Codable, Equatable, Sendable {
    /// メインカテゴリ（文字列形式）
    public var mainCategory: String

    public init(mainCategory: String) {
        self.mainCategory = mainCategory
    }
}

/// @ai[2025-10-21 15:10] サブカテゴリ情報構造体
/// @ai[2025-10-22 20:00] confidence削除（信頼性評価は不要）
/// @ai[2025-11-05 17:00] @Generableマクロ削除（TwoSteps抽出はJSON方式のみ）
/// 目的: 第2段階のサブカテゴリ判定結果を格納（JSON抽出用）
/// 背景: 2層判定の第2段階で使用、@GenerableはOne-step抽出専用
/// 意図: メインカテゴリ配下の5つのサブカテゴリから1つを判定（JSON形式）
@available(iOS 26.0, macOS 26.0, *)
public struct SubCategoryInfo: Codable, Equatable, Sendable {
    /// サブカテゴリ（文字列形式）
    public var subCategory: String

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

    public init(
        mainCategory: String,
        subCategory: String
    ) {
        self.mainCategory = mainCategory
        self.subCategory = subCategory
    }
}
