import Foundation

/// @ai[2025-01-19 01:00] レポート生成ユーティリティ
/// 目的: レポート生成処理を一元化
/// 背景: main.swiftの肥大化を防ぐため、レポート関連の処理を分離
/// 意図: 保守性の向上とコードの可読性向上

/// HTMLレポートを生成
public func generateHTMLReport(data: [(testCase: String, method: String, language: String, result: String, metrics: String)]) -> String {
    let timestamp = DateFormatter().string(from: Date())
    
    var html = """
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>AITest 実験結果レポート</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
            .section { margin: 20px 0; }
            .test-case { border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; }
            .success { border-left: 5px solid #4CAF50; }
            .error { border-left: 5px solid #f44336; }
            .metrics { background-color: #f9f9f9; padding: 10px; margin: 10px 0; border-radius: 3px; }
            .result { white-space: pre-wrap; font-family: monospace; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🤖 AITest 実験結果レポート</h1>
            <p>生成日時: \(timestamp)</p>
            <p>総テスト数: \(data.count)</p>
        </div>
    """
    
    for item in data {
        let statusClass = item.result.contains("Error") ? "error" : "success"
        html += """
        <div class="test-case \(statusClass)">
            <h3>\(item.testCase)</h3>
            <p><strong>メソッド:</strong> \(item.method)</p>
            <p><strong>言語:</strong> \(item.language)</p>
            <div class="metrics">
                <h4>メトリクス:</h4>
                <div class="result">\(item.metrics)</div>
            </div>
            <div class="result">
                <h4>結果:</h4>
                <div class="result">\(item.result)</div>
            </div>
        </div>
        """
    }
    
    html += """
    </body>
    </html>
    """
    
    return html
}

/// ログディレクトリを作成
public func createLogDirectory(_ path: String) {
    print("🔍 DEBUG: createLogDirectory開始 - パス: \(path)")
    
    let fileManager = FileManager.default
    
    do {
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        print("✅ ログディレクトリ作成完了: \(path)")
    } catch {
        print("❌ ログディレクトリ作成エラー: \(error.localizedDescription)")
    }
}
