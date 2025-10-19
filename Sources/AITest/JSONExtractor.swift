import Foundation

/// @ai[2025-01-19 00:30] 統一されたJSON抽出処理
/// 目的: FoundationModelsと外部LLMのJSON抽出処理を統一
/// 背景: コードの重複を排除し、保守性を向上
/// 意図: JSON抽出ロジックの一元化

/// 統一されたJSON抽出器
/// @ai[2025-01-19 00:30] JSON抽出の統一実装
/// 目的: モデルに依存しないJSON抽出処理を提供
/// 背景: FoundationModelsと外部LLMで共通のJSON抽出ロジックが必要
/// 意図: JSON抽出処理の一元化とコードの重複排除
@available(iOS 26.0, macOS 26.0, *)
public class JSONExtractor {
    private let log = LogWrapper(subsystem: "com.aitest.json", category: "JSONExtractor")
    
    public init() {}
    
    /// JSON文字列からAccountInfoを抽出
    /// @ai[2025-01-19 00:30] 統一されたJSON抽出処理
    /// 目的: モデルに依存しないJSON抽出を実装
    /// 背景: FoundationModelsと外部LLMで共通のJSON抽出ロジックが必要
    /// 意図: JSON抽出処理の一元化
    public func extractFromJSONText(_ jsonString: String) -> (AccountInfo?, Error?) {
        log.debug("🔍 JSON文字列解析開始")
        log.debug("📝 JSON文字列: \(jsonString)")
        
        // 最初にJSON文字列をサニタイズ
        let sanitizedJSON = sanitizeJSONString(jsonString)
        
        // 複数のJSON抽出パターンを試行
        let jsonPatterns = [
            // パターン1: ```json ... ``` で囲まれたJSON
            extractJSONFromCodeBlock(sanitizedJSON),
            // パターン2: assistantfinal の後のJSON
            extractJSONAfterAssistantFinal(sanitizedJSON),
            // パターン3: 最初の{から最後の}まで
            extractJSONFromBraces(sanitizedJSON),
            // パターン4: 全体がJSON
            sanitizedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        
        for (index, jsonCandidate) in jsonPatterns.enumerated() {
            guard !jsonCandidate.isEmpty else { continue }
            
            log.debug("📝 パターン\(index + 1) JSON候補: \(jsonCandidate)")
            
            // ポート番号の文字列を数値に変換してからパース
            let normalizedJSON = normalizePortField(jsonCandidate)
            
            if let accountInfo = tryParseJSON(normalizedJSON) {
                log.debug("✅ JSON解析完了（パターン\(index + 1)）")
                return (accountInfo, nil)
            }
        }
        
        log.error("❌ すべてのJSON抽出パターンが失敗")
        log.error("📝 レスポンス全体: \(jsonString)")
        return (nil, ExtractionError.invalidJSONFormat(aiResponse: jsonString))
    }
    
    /// ```json ... ``` で囲まれたJSONを抽出
    private func extractJSONFromCodeBlock(_ text: String) -> String {
        let codeBlockPattern = #"```json\s*([\s\S]*?)\s*```"#
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let jsonRange = Range(match.range(at: 1), in: text) {
                    let extractedJSON = String(text[jsonRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "\\n", with: "\n")
                        .replacingOccurrences(of: "\\t", with: "\t")
                        .replacingOccurrences(of: "\\r", with: "\r")
                    return extractedJSON
                }
            }
        }
        return ""
    }
    
    /// assistantfinal の後のJSONを抽出
    private func extractJSONAfterAssistantFinal(_ text: String) -> String {
        let assistantFinalPattern = #"assistantfinal\s*:\s*([\s\S]*)"#
        if let regex = try? NSRegularExpression(pattern: assistantFinalPattern, options: [.caseInsensitive]) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let jsonRange = Range(match.range(at: 1), in: text) {
                    return String(text[jsonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return ""
    }
    
    /// 最初の{から最後の}までを抽出
    private func extractJSONFromBraces(_ text: String) -> String {
        guard let firstBrace = text.firstIndex(of: "{"),
              let lastBrace = text.lastIndex(of: "}") else {
            return ""
        }
        
        let endIndex = lastBrace
        let jsonString = String(text[firstBrace...endIndex])
        
        return jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// JSON文字列をサニタイズ
    /// @ai[2025-01-19 00:30] JSON文字列サニタイズの統一処理
    /// 目的: 文字列内の改行文字のみをエスケープしてJSONを有効にする
    /// 背景: AIのレスポンスに含まれる改行文字がJSONを無効にする問題を解決
    /// 意図: JSON構造を保持しながら文字列内の改行を適切にエスケープ
    private func sanitizeJSONString(_ jsonString: String) -> String {
        log.debug("🔧 JSON文字列サニタイズ開始")
        log.debug("📝 元のJSON: \(jsonString)")

        var result = ""
        var i = jsonString.startIndex
        var inString = false
        var escapeNext = false

        while i < jsonString.endIndex {
            let char = jsonString[i]

            if escapeNext {
                // エスケープ文字の次の文字はそのまま追加
                result.append(char)
                escapeNext = false
            } else if char == "\\" {
                // バックスラッシュの場合はエスケープフラグを設定
                result.append(char)
                escapeNext = true
            } else if char == "\"" && !escapeNext {
                // ダブルクォートの場合は文字列内外の状態を切り替え
                result.append(char)
                inString.toggle()
            } else if inString && (char == "\n" || char == "\r" || char == "\t") {
                // 文字列内の改行文字のみをエスケープ
                switch char {
                case "\n":
                    result.append("\\n")
                case "\r":
                    result.append("\\r")
                case "\t":
                    result.append("\\t")
                default:
                    result.append(char)
                }
            } else {
                // その他の文字はそのまま追加
                result.append(char)
            }

            i = jsonString.index(after: i)
        }

        // 既にエスケープされた文字列を正規化
        // \\n -> \n に変換（JSON内の文字列値として正しい形式）
        result = result.replacingOccurrences(of: "\\\\n", with: "\\n")
        result = result.replacingOccurrences(of: "\\\\r", with: "\\r")
        result = result.replacingOccurrences(of: "\\\\t", with: "\\t")

        log.debug("📝 サニタイズ後JSON: \(result)")

        return result
    }
    
    /// ポート番号の文字列を数値に変換
    /// @ai[2025-01-19 00:30] ポート番号正規化の統一処理
    /// 目的: "port": "22" を "port": 22 に変換してJSONデコードエラーを回避
    /// 背景: AccountInfo.portはInt型だが、AIが文字列で返すことがある
    /// 意図: 型の不一致によるデコードエラーを防ぎ、抽出成功率を向上
    private func normalizePortField(_ jsonString: String) -> String {
        log.debug("🔧 ポート番号正規化開始")
        log.debug("📝 元のJSON: \(jsonString)")
        
        // "port": "22" のパターンを "port": 22 に変換（カンマや閉じ括弧の前まで）
        let portPattern = #""port"\s*:\s*"(\d+)"(?=\s*[,}])"#
        if let regex = try? NSRegularExpression(pattern: portPattern, options: []) {
            let range = NSRange(jsonString.startIndex..<jsonString.endIndex, in: jsonString)
            var normalizedJSON = jsonString
            var offset = 0
            var matchCount = 0
            
            regex.enumerateMatches(in: jsonString, options: [], range: range) { match, _, _ in
                guard let match = match,
                      let portRange = Range(match.range(at: 1), in: jsonString) else { return }
                
                let portString = String(jsonString[portRange])
                let replacement = "\"port\": \(portString)"
                matchCount += 1
                
                log.debug("🔧 ポート番号発見: \(portString) -> \(replacement)")
                
                // 範囲を調整（前の置換によるオフセットを考慮）
                let adjustedRange = NSRange(
                    location: match.range.location - offset,
                    length: match.range.length
                )
                
                normalizedJSON = (normalizedJSON as NSString).replacingCharacters(
                    in: adjustedRange,
                    with: replacement
                )
                
                offset += match.range.length - replacement.count
            }
            
            log.debug("📝 正規化後JSON: \(normalizedJSON)")
            log.debug("🔧 ポート番号置換回数: \(matchCount)")
            
            return normalizedJSON
        }
        
        log.debug("🔧 ポート番号パターンが見つかりませんでした")
        return jsonString
    }
    
    /// JSONをパースしてAccountInfoに変換
    private func tryParseJSON(_ jsonString: String) -> AccountInfo? {
        guard let data = jsonString.data(using: .utf8) else {
            log.debug("❌ JSON文字列のデータ変換失敗")
            return nil
        }
        
        do {
            let accountInfo = try JSONDecoder().decode(AccountInfo.self, from: data)
            log.debug("✅ JSONデコード成功")
            return accountInfo
        } catch {
            log.debug("❌ JSONデコードエラー: \(error)")
            return nil
        }
    }
}
