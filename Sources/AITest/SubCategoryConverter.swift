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

    /// Generable構造体をAccountInfoに変換（Anyオブジェクト版）
    /// @ai[2025-10-21 19:00] 後方互換性のため残す
    /// @ai[2025-10-23 10:00] デバッグログ追加
    /// 目的: 既存のAnyオブジェクトベースの呼び出しに対応
    /// 背景: FoundationModelsExtractorのextractAndConvertで使用
    /// 意図: 内部でJSONに変換してから新しいconvertを呼び出す
    public func convert(_ subcategoryStruct: Any) -> AccountInfo {
        // Anyオブジェクトの型名からサブカテゴリを推測
        let typeName = String(describing: type(of: subcategoryStruct))
        log.debug("🔄 変換開始(Any版) - 型名: \(typeName)")

        guard let subCategory = inferSubCategory(from: typeName) else {
            log.error("❌ サブカテゴリを推測できません: \(typeName)")
            return AccountInfo()
        }

        log.debug("✅ サブカテゴリ推測成功: \(subCategory.rawValue)")

        // CodableオブジェクトをJSONに変換
        guard let json = convertToJSON(subcategoryStruct) else {
            log.error("❌ JSON変換に失敗しました")
            return AccountInfo()
        }

        log.debug("✅ JSON変換成功")

        // JSON形式のconvertを呼び出す
        return convert(from: json, subCategory: subCategory)
    }

    /// JSON形式からAccountInfoに変換（マッピングルールベース）
    /// @ai[2025-10-21 19:00] 新しい統一変換ロジック
    /// @ai[2025-10-23 10:00] デバッグログ追加（マッピングルール適用状況を詳細表示）
    /// @ai[2025-10-24 12:00] CategoryDefinitionLoaderのマッピング定義を使用
    /// 目的: JSON形式のデータをマッピングルールに従ってAccountInfoに変換
    /// 背景: JSON形式とGenerable形式の両方に対応
    /// 意図: マッピングルールの外部化により柔軟性と保守性を向上
    public func convert(from json: [String: Any], subCategory: SubCategory) -> AccountInfo {
        log.debug("🔄 変換開始 - サブカテゴリ: \(subCategory.rawValue)")
        log.debug("📋 入力JSON: \(json)")

        var accountInfo = AccountInfo()

        do {
            // サブカテゴリ定義からマッピング情報を読み込み
            let definition = try categoryLoader.loadSubCategoryDefinition(subCategoryId: subCategory.rawValue)
            let mapping = definition.mapping
            log.debug("✅ マッピング情報読み込み完了")
            log.debug("📋 directMapping: \(mapping.directMapping)")
            if let noteAppend = mapping.noteAppendMapping {
                log.debug("📋 noteAppendMapping: \(noteAppend)")
            }

            // 直接マッピングを適用
            for (sourceField, targetField) in mapping.directMapping {
                guard let value = json[sourceField] else {
                    log.debug("⚠️ フィールド '\(sourceField)' が見つかりません")
                    continue
                }

                log.debug("✅ マッピング適用: \(sourceField) -> \(targetField), 値: \(value)")

                switch targetField {
                case "title":
                    accountInfo.title = stringify(value)
                case "userID":
                    accountInfo.userID = stringify(value)
                case "password":
                    accountInfo.password = stringify(value)
                case "host":
                    accountInfo.host = stringify(value)
                case "port":
                    if let intValue = value as? Int {
                        accountInfo.port = intValue
                    } else if let stringValue = value as? String, let intValue = Int(stringValue) {
                        accountInfo.port = intValue
                    }
                case "url":
                    accountInfo.url = stringify(value)
                case "note":
                    accountInfo.note = stringify(value)
                default:
                    log.debug("⚠️ 未知のターゲットフィールド: \(targetField)")
                }
            }

            // noteに追加するフィールドを処理
            if let noteAppendMapping = mapping.noteAppendMapping {
                var additionalNotes: [String] = []

                for (sourceField, label) in noteAppendMapping {
                    guard let value = json[sourceField],
                          let stringValue = stringify(value),
                          !stringValue.isEmpty else { continue }

                    additionalNotes.append("\(label): \(stringValue)")
                }

                // 既存のnoteに追加
                if !additionalNotes.isEmpty {
                    let combinedNotes = additionalNotes.joined(separator: "\n")
                    if let existingNote = accountInfo.note, !existingNote.isEmpty {
                        accountInfo.note = "\(existingNote)\n\n【詳細情報】\n\(combinedNotes)"
                    } else {
                        accountInfo.note = combinedNotes
                    }
                }
            }

            log.debug("✅ 変換完了 - subCategory: \(subCategory.rawValue), title: \(accountInfo.title ?? "nil")")

        } catch {
            log.error("❌ サブカテゴリ定義読み込みエラー: \(error.localizedDescription)")
        }

        return accountInfo
    }

    // MARK: - Private Methods

    /// 型名からサブカテゴリを推測
    private func inferSubCategory(from typeName: String) -> SubCategory? {
        // 型名とサブカテゴリのマッピング
        let typeMapping: [String: SubCategory] = [
            "PersonalHomeInfo": .personalHome,
            "PersonalEducationInfo": .personalEducation,
            "PersonalHealthInfo": .personalHealth,
            "PersonalContactsInfo": .personalContacts,
            "PersonalOtherInfo": .personalOther,

            "FinancialBankingInfo": .financialBanking,
            "FinancialCreditCardInfo": .financialCreditCard,
            "FinancialPaymentInfo": .financialPayment,
            "FinancialInsuranceInfo": .financialInsurance,
            "FinancialCryptoInfo": .financialCrypto,

            "DigitalSubscriptionInfo": .digitalSubscription,
            "DigitalAIInfo": .digitalAI,
            "DigitalSocialInfo": .digitalSocial,
            "DigitalShoppingInfo": .digitalShopping,
            "DigitalAppsInfo": .digitalApps,

            "WorkServerInfo": .workServer,
            "WorkSaaSInfo": .workSaaS,
            "WorkDevelopmentInfo": .workDevelopment,
            "WorkCommunicationInfo": .workCommunication,
            "WorkOtherInfo": .workOther,

            "InfraTelecomInfo": .infraTelecom,
            "InfraUtilitiesInfo": .infraUtilities,
            "InfraGovernmentInfo": .infraGovernment,
            "InfraLicenseInfo": .infraLicense,
            "InfraTransportationInfo": .infraTransportation
        ]

        return typeMapping[typeName]
    }

    /// CodableオブジェクトをJSON Dictionaryに変換
    private func convertToJSON(_ object: Any) -> [String: Any]? {
        guard let encodable = object as? Encodable else {
            log.error("❌ オブジェクトがEncodableではありません")
            return nil
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(encodable)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any]
        } catch {
            log.error("❌ JSON変換エラー: \(error.localizedDescription)")
            return nil
        }
    }

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
