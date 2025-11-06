import Foundation

/// @ai[2025-10-21 16:30] サブカテゴリ構造体→AccountInfo変換器
/// @ai[2025-10-21 19:00] JSON形式とマッピングルールベースに改善
/// @ai[2025-10-24 12:00] CategoryDefinitionLoaderに統合（Mappingsディレクトリ削除）
/// 目的: サブカテゴリごとの専用構造体を統一的にAccountInfoに変換
/// 背景: JSON形式とGenerable形式の両方に対応し、マッピングルールを外部化
/// 意図: 柔軟で保守性の高い変換ロジックを提供

@available(iOS 26.0, macOS 26.0, *)
public class SubCategoryConverter {
    private let log = LogWrapper(subsystem: "com.aitest.converter", category: "SubCategoryConverter")
    private let categoryLoader = CategoryDefinitionLoader()

    public init() {}

    // 旧AnyベースAPIは削除（新mappingのみ対応）

    /// JSON形式からAccountInfoに変換（マッピングルールベース）
    /// @ai[2025-10-21 19:00] 新しい統一変換ロジック
    /// @ai[2025-10-23 10:00] デバッグログ追加（マッピングルール適用状況を詳細表示）
    /// @ai[2025-10-24 12:00] CategoryDefinitionLoaderのマッピング定義を使用
    /// @ai[2025-11-05 18:00] String型に変更（enum削除）
    /// 目的: JSON形式のデータをマッピングルールに従ってAccountInfoに変換
    /// 背景: JSON形式とGenerable形式の両方に対応
    /// 意図: マッピングルールの外部化により柔軟性と保守性を向上
    public func convert(from json: [String: Any], subCategory: String) -> AccountInfo {
        log.debug("🔄 変換開始 - サブカテゴリ: \(subCategory)")
        log.debug("📋 入力JSON: \(json)")

        var accountInfo = AccountInfo()

        do {
            // サブカテゴリ定義から新mapping配列を読み込み
            let definition = try categoryLoader.loadSubCategoryDefinition(subCategoryId: subCategory)
            let fields = definition.mapping.ja ?? definition.mapping.en ?? []
            log.debug("✅ 新mapping配列読み込み完了: \(fields.count)項目")

            // noteに追記するためのバッファ
            var appendedNotes: [String] = []

            for field in fields {
                let jsonKey = field.name
                guard let rawValue = json[jsonKey] else { continue }

                let key = (field.mappingKey?.isEmpty == false) ? field.mappingKey! : jsonKey

                // note:append の場合はformatに従って追記
                if key == "note:append" {
                    if let s = stringify(rawValue), !s.isEmpty {
                        if let fmt = field.format, !fmt.isEmpty {
                            appendedNotes.append(String(format: fmt.replacingOccurrences(of: "%@", with: "%@"), s))
                        } else if let label = field.description, !label.isEmpty {
                            appendedNotes.append("\(label): \(s)")
                        } else {
                            appendedNotes.append(s)
                        }
                    }
                    continue
                }

                switch key {
                case "title":
                    accountInfo.title = stringify(rawValue)
                case "userID":
                    accountInfo.userID = stringify(rawValue)
                case "password":
                    accountInfo.password = stringify(rawValue)
                case "host":
                    accountInfo.host = stringify(rawValue)
                case "port":
                    if let intValue = rawValue as? Int {
                        accountInfo.port = intValue
                    } else if let stringValue = rawValue as? String, let intValue = Int(stringValue) {
                        accountInfo.port = intValue
                    }
                case "url":
                    accountInfo.url = stringify(rawValue)
                case "note":
                    accountInfo.note = stringify(rawValue)
                default:
                    // AccountInfoに直接マップしないフィールドは無視
                    break
                }
            }

            if !appendedNotes.isEmpty {
                let extra = appendedNotes.joined(separator: "\n")
                if let existing = accountInfo.note, !existing.isEmpty {
                    accountInfo.note = "\(existing)\n\n\(extra)"
                } else {
                    accountInfo.note = extra
                }
            }

            log.debug("✅ 変換完了 - subCategory: \(subCategory), title: \(accountInfo.title ?? "nil")")
        } catch {
            log.error("❌ サブカテゴリ定義読み込みエラー: \(error.localizedDescription)")
        }

        return accountInfo
    }

    // MARK: - Private Methods

    // 型名推測ロジックは削除（Generable互換廃止）

    // Any→JSON変換は削除

    /// 値を文字列に変換
    private func stringify(_ value: Any) -> String? {
        if let stringValue = value as? String {
            return stringValue.isEmpty ? nil : stringValue
        } else if let intValue = value as? Int {
            return String(intValue)
        } else if let doubleValue = value as? Double {
            return String(doubleValue)
        } else if let boolValue = value as? Bool {
            return String(boolValue)
        } else {
            return String(describing: value)
        }
    }
}

