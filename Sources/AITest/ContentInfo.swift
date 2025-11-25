import Foundation

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
