import Foundation

/// @ai[2025-10-21 19:00] マッピングルール定義
/// 目的: サブカテゴリ構造体からAccountInfoへの変換ルールを外部JSON化
/// 背景: 固定コードによるマッピングでは柔軟性に欠ける
/// 意図: JSONファイルでマッピングルールを定義し、保守性と拡張性を向上

/// マッピングルール（JSON形式で定義）
@available(iOS 26.0, macOS 26.0, *)
public struct MappingRule: Codable {
    /// サブカテゴリ
    public let subCategory: String

    /// 直接マッピング（ソースフィールド名 → AccountInfoフィールド名）
    /// 例: { "title": "title", "username": "userID", "password": "password" }
    public let directMapping: [String: String]

    /// noteに追加するフィールド（ソースフィールド名 → 日本語ラベル）
    /// 例: { "address": "住所", "electricityAccount": "電気契約番号" }
    public let noteAppendMapping: [String: String]?

    /// カスタム変換ルール（将来の拡張用）
    public let customRules: [String: String]?

    public init(
        subCategory: String,
        directMapping: [String: String],
        noteAppendMapping: [String: String]? = nil,
        customRules: [String: String]? = nil
    ) {
        self.subCategory = subCategory
        self.directMapping = directMapping
        self.noteAppendMapping = noteAppendMapping
        self.customRules = customRules
    }
}

/// マッピングルールローダー
@available(iOS 26.0, macOS 26.0, *)
public class MappingRuleLoader {
    private let log = LogWrapper(subsystem: "com.aitest.mapping", category: "MappingRuleLoader")
    private var cachedRules: [String: MappingRule] = [:]

    public init() {}

    /// マッピングルールを読み込み（キャッシュ対応）
    /// @ai[2025-10-21 19:00] マッピングルール読み込み
    /// @ai[2025-10-22 18:20] プロンプトファイルと同様の読み込み方法に変更、fatalerror追加
    /// 目的: サブカテゴリごとのマッピングルールJSONをロード
    /// 背景: 各サブカテゴリ用のマッピング定義を外部化
    /// 意図: キャッシュにより2回目以降の読み込みを高速化、見つからない場合は強制終了
    public func loadRule(for subCategory: SubCategory) throws -> MappingRule {
        let key = subCategory.rawValue

        // キャッシュチェック
        if let cached = cachedRules[key] {
            return cached
        }

        // JSONファイルを読み込み
        let fileName = "\(key)_mapping.json"

        // Try with subdirectory first
        var resourceURL = Bundle.module.url(forResource: fileName, withExtension: nil, subdirectory: "Mappings")

        // If not found, try without subdirectory
        if resourceURL == nil {
            resourceURL = Bundle.module.url(forResource: fileName, withExtension: nil)
        }

        guard let resourceURL = resourceURL else {
            log.error("❌ マッピングルールが見つかりません: \(fileName)")
            log.error("❌ Bundle.module.resourceURL: \(String(describing: Bundle.module.resourceURL))")
            log.error("❌ Bundle.module.bundlePath: \(Bundle.module.bundlePath)")

            // マッピングルールファイルは必須なので、見つからない場合は強制終了
            fatalError("❌ 必須のマッピングルールファイルが見つかりません: \(fileName)\nサブカテゴリ: \(key)\nプロジェクトのビルド設定を確認してください。")
        }

        let data = try Data(contentsOf: resourceURL)
        let decoder = JSONDecoder()
        let rule = try decoder.decode(MappingRule.self, from: data)

        // キャッシュに保存
        cachedRules[key] = rule
        log.debug("✅ マッピングルール読み込み成功: \(fileName)")

        return rule
    }

    /// キャッシュをクリア
    public func clearCache() {
        cachedRules.removeAll()
        log.debug("🗑️ マッピングルールキャッシュをクリア")
    }
}
