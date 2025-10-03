import Foundation

/// @ai[2024-12-19 20:45] HTMLレポート生成器
/// ベンチマーク結果をHTMLレポートとして出力
@available(iOS 26.0, macOS 26.0, *)
public class HTMLReportGenerator {
    
    /// HTMLレポートを生成
    public static func generateReport(
        results: [RepeatedTestResult],
        statistics: BenchmarkStatistics?,
        outputPath: String = "/Users/t.miyano/repos/AITest/benchmark_report.html"
    ) throws {
        let html = generateHTMLContent(results: results, statistics: statistics)
        
        try html.write(toFile: outputPath, atomically: true, encoding: .utf8)
        print("📊 HTMLレポートを生成しました: \(outputPath)")
    }
    
    /// HTMLコンテンツを生成
    private static func generateHTMLContent(
        results: [RepeatedTestResult],
        statistics: BenchmarkStatistics?
    ) -> String {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        
        return """
        <!DOCTYPE html>
        <html lang="ja">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>FoundationModels 性能評価レポート</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    margin: 0;
                    padding: 20px;
                    background-color: #f5f5f7;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 12px;
                    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                    overflow: hidden;
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 30px;
                    text-align: center;
                }
                .header h1 {
                    margin: 0;
                    font-size: 2.5em;
                    font-weight: 300;
                }
                .header p {
                    margin: 10px 0 0 0;
                    opacity: 0.9;
                }
                .content {
                    padding: 30px;
                }
                .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                    gap: 20px;
                    margin-bottom: 30px;
                }
                .stat-card {
                    background: #f8f9fa;
                    border-radius: 8px;
                    padding: 20px;
                    text-align: center;
                    border-left: 4px solid #007AFF;
                }
                .stat-value {
                    font-size: 2em;
                    font-weight: bold;
                    color: #007AFF;
                    margin-bottom: 5px;
                }
                .stat-label {
                    color: #666;
                    font-size: 0.9em;
                }
                .test-results {
                    margin-top: 30px;
                }
                .test-card {
                    background: white;
                    border: 1px solid #e1e5e9;
                    border-radius: 8px;
                    margin-bottom: 20px;
                    overflow: hidden;
                }
                .test-header {
                    background: #f8f9fa;
                    padding: 15px 20px;
                    border-bottom: 1px solid #e1e5e9;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                .test-title {
                    font-weight: 600;
                    color: #1d1d1f;
                }
                .test-meta {
                    color: #666;
                    font-size: 0.9em;
                }
                .test-content {
                    padding: 20px;
                }
                .metrics-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
                    gap: 15px;
                    margin-bottom: 20px;
                }
                .metric {
                    text-align: center;
                    padding: 10px;
                    background: #f8f9fa;
                    border-radius: 6px;
                }
                .metric-value {
                    font-weight: bold;
                    color: #007AFF;
                }
                .metric-label {
                    font-size: 0.8em;
                    color: #666;
                    margin-top: 2px;
                }
                .success-rate {
                    display: inline-block;
                    padding: 4px 12px;
                    border-radius: 20px;
                    font-weight: 600;
                    font-size: 0.9em;
                }
                .success-high { background: #d4edda; color: #155724; }
                .success-medium { background: #fff3cd; color: #856404; }
                .success-low { background: #f8d7da; color: #721c24; }
                .chart-container {
                    margin: 20px 0;
                    padding: 20px;
                    background: #f8f9fa;
                    border-radius: 8px;
                }
                .progress-bar {
                    width: 100%;
                    height: 8px;
                    background: #e1e5e9;
                    border-radius: 4px;
                    overflow: hidden;
                    margin: 10px 0;
                }
                .progress-fill {
                    height: 100%;
                    background: linear-gradient(90deg, #007AFF, #5AC8FA);
                    transition: width 0.3s ease;
                }
                .warning-list {
                    margin-top: 15px;
                }
                .warning-item {
                    background: #fff3cd;
                    border: 1px solid #ffeaa7;
                    border-radius: 4px;
                    padding: 8px 12px;
                    margin: 5px 0;
                    font-size: 0.9em;
                }
                .footer {
                    background: #f8f9fa;
                    padding: 20px;
                    text-align: center;
                    color: #666;
                    border-top: 1px solid #e1e5e9;
                }
                
                /* note内容分析スタイル */
                .note-analysis {
                    margin-top: 20px;
                    padding: 15px;
                    background: #e8f4fd;
                    border-radius: 8px;
                    border: 1px solid #b3d9ff;
                }
                
                .note-analysis h4 {
                    margin: 0 0 15px 0;
                    color: #0066cc;
                    font-size: 14px;
                    font-weight: 600;
                }
                
                .note-metrics {
                    display: flex;
                    gap: 20px;
                    margin-bottom: 15px;
                }
                
                .note-metric {
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                }
                
                .note-label {
                    font-size: 12px;
                    color: #666;
                    margin-bottom: 5px;
                }
                
                .note-value {
                    font-size: 18px;
                    font-weight: 700;
                    color: #0066cc;
                }
                
                .note-content {
                    background: white;
                    padding: 10px;
                    border-radius: 4px;
                    border: 1px solid #b3d9ff;
                }
                
                .note-text {
                    font-size: 12px;
                    color: #333;
                    line-height: 1.4;
                }
                
                /* AI回答分析スタイル */
                .ai-analysis {
                    margin-top: 20px;
                    padding: 15px;
                    background: #f0f8f0;
                    border-radius: 8px;
                    border: 1px solid #90ee90;
                }
                
                .ai-analysis h4 {
                    margin: 0 0 15px 0;
                    color: #228b22;
                    font-size: 14px;
                    font-weight: 600;
                }
                
                .ai-insights {
                    background: white;
                    padding: 15px;
                    border-radius: 4px;
                    border: 1px solid #90ee90;
                    font-size: 13px;
                    line-height: 1.5;
                    color: #333;
                    margin-bottom: 15px;
                }
                
                .ai-issues, .ai-patterns {
                    margin-bottom: 15px;
                }
                
                .ai-issues h5, .ai-patterns h5 {
                    margin: 0 0 10px 0;
                    font-size: 13px;
                    color: #228b22;
                    font-weight: 600;
                }
                
                .ai-issues ul, .ai-patterns ul {
                    margin: 0;
                    padding-left: 20px;
                }
                
                .ai-issues li, .ai-patterns li {
                    font-size: 12px;
                    color: #333;
                    margin-bottom: 5px;
                }
                
                .field-accuracy, .field-expected {
                    font-size: 10px;
                    color: #666;
                    margin-top: 4px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🚀 FoundationModels 性能評価レポート</h1>
                    <p>Apple Intelligence Foundation Model の Account 情報抽出性能測定</p>
                    <p>生成日時: \(timestamp)</p>
                </div>
                
                <div class="content">
                    \(generateStatisticsSection(statistics: statistics))
                    \(generateTestResultsSection(results: results))
                </div>
                
                <div class="footer">
                    <p>Generated by AITest - FoundationModels Performance Evaluation Tool</p>
                </div>
            </div>
        </body>
        </html>
        """
    }
    
    /// 統計情報セクションを生成
    private static func generateStatisticsSection(statistics: BenchmarkStatistics?) -> String {
        guard let stats = statistics else {
            return """
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-value">-</div>
                    <div class="stat-label">統計情報なし</div>
                </div>
            </div>
            """
        }
        
        let successRateClass = stats.successRate >= 0.8 ? "success-high" : 
                              stats.successRate >= 0.6 ? "success-medium" : "success-low"
        
        return """
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value">\(stats.totalTests)</div>
                <div class="stat-label">総テスト数</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">\(stats.successfulTests)</div>
                <div class="stat-label">成功テスト数</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">\(String(format: "%.1f", stats.successRate * 100))%</div>
                <div class="stat-label">成功率</div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: \(stats.successRate * 100)%"></div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-value">\(String(format: "%.3f", stats.averageExtractionTime))s</div>
                <div class="stat-label">平均抽出時間</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">\(String(format: "%.1f", stats.averageMemoryUsage))MB</div>
                <div class="stat-label">平均メモリ使用量</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">\(String(format: "%.2f", stats.averageConfidence))</div>
                <div class="stat-label">平均信頼度</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">\(String(format: "%.1f", stats.averageFieldCount))</div>
                <div class="stat-label">平均抽出フィールド数</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">\(String(format: "%.3f", stats.minExtractionTime))s</div>
                <div class="stat-label">最短抽出時間</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">\(String(format: "%.3f", stats.maxExtractionTime))s</div>
                <div class="stat-label">最長抽出時間</div>
            </div>
        </div>
        
        \(generateWarningAnalysisSection(stats: stats))
        """
    }
    
    /// 警告分析セクションを生成
    private static func generateWarningAnalysisSection(stats: BenchmarkStatistics) -> String {
        guard !stats.warningCounts.isEmpty else {
            return """
            <div class="chart-container">
                <h3>✅ バリデーション警告分析</h3>
                <p>警告なし - すべての抽出結果が正常です</p>
            </div>
            """
        }
        
        let warningItems = stats.warningCounts.map { (warning, count) in
            """
            <div class="warning-item">
                <strong>\(warning):</strong> \(count)回
            </div>
            """
        }.joined(separator: "")
        
        return """
        <div class="chart-container">
            <h3>⚠️ バリデーション警告分析</h3>
            <div class="warning-list">
                \(warningItems)
            </div>
        </div>
        """
    }
    
    /// テスト結果セクションを生成
    private static func generateTestResultsSection(results: [RepeatedTestResult]) -> String {
        let testCards = results.enumerated().map { (index, result) in
            generateTestCard(testIndex: index, result: result)
        }.joined(separator: "")
        
        return """
        <div class="test-results">
            <h2>📊 テスト結果詳細</h2>
            \(testCards)
        </div>
        """
    }
    
    /// 個別テストカードを生成
    private static func generateTestCard(testIndex: Int, result: RepeatedTestResult) -> String {
        let successRateClass = result.successRate >= 0.8 ? "success-high" : 
                              result.successRate >= 0.6 ? "success-medium" : "success-low"
        
        let testName = getTestName(testIndex: testIndex)
        
        return """
        <div class="test-card">
            <div class="test-header">
                <div class="test-title">\(testName)</div>
                <div class="test-meta">
                    <span class="success-rate \(successRateClass)">\(String(format: "%.1f", result.successRate * 100))%</span>
                </div>
            </div>
            <div class="test-content">
                <div class="metrics-grid">
                    <div class="metric">
                        <div class="metric-value">\(String(format: "%.3f", result.averageExtractionTime))s</div>
                        <div class="metric-label">平均抽出時間</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(String(format: "%.2f", result.averageConfidence))</div>
                        <div class="metric-label">平均信頼度</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(result.results.count)</div>
                        <div class="metric-label">実行回数</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(result.results.filter { $0.success }.count)</div>
                        <div class="metric-label">成功回数</div>
                    </div>
                </div>
                
                <!-- 項目レベル分析 -->
                <div class="field-analysis">
                    <h4>📊 項目別成功率</h4>
                    <div class="field-grid">
                        \(generateFieldAnalysisHTML(result.fieldAnalysis))
                    </div>
                </div>
                
                <!-- note内容分析 -->
                \(generateNoteAnalysisHTML(result.fieldAnalysis.noteContentAnalysis))
                
                <!-- AI回答分析 -->
                \(generateAIResponseAnalysisHTML(result.fieldAnalysis.aiResponseAnalysis))
                
                <div class="progress-bar">
                    <div class="progress-fill" style="width: \(result.successRate * 100)%"></div>
                </div>
            </div>
        </div>
        """
    }
    
    /// 項目レベル分析のHTMLを生成
    private static func generateFieldAnalysisHTML(_ fieldAnalysis: FieldLevelAnalysis) -> String {
        let fields = ["title", "userID", "password", "url", "note", "host", "port", "authKey"]
        let fieldNames = [
            "title": "サービス名",
            "userID": "ユーザーID", 
            "password": "パスワード",
            "url": "URL",
            "note": "備考",
            "host": "ホスト",
            "port": "ポート",
            "authKey": "認証キー"
        ]
        
        let fieldCards = fields.compactMap { field -> String? in
            let successRate = fieldAnalysis.fieldSuccessRates[field] ?? 0.0
            let extractionCount = fieldAnalysis.fieldExtractionCounts[field] ?? 0
            let errorCount = fieldAnalysis.fieldErrorCounts[field] ?? 0
            let characterAccuracy = fieldAnalysis.fieldCharacterAccuracy[field] ?? 0.0
            let expectedValue = fieldAnalysis.fieldExpectedValues[field]
            
            // 含まれていない項目は表示しない
            guard extractionCount > 0 || expectedValue != nil else { return nil }
            
            let fieldName = fieldNames[field] ?? field
            let successClass = successRate >= 0.8 ? "field-success" : successRate >= 0.6 ? "field-warning" : "field-error"
            
            var fieldInfo = """
            <div class="field-card">
                <div class="field-name">\(fieldName)</div>
                <div class="field-metrics">
                    <div class="field-success-rate \(successClass)">\(String(format: "%.1f", successRate * 100))%</div>
                    <div class="field-counts">
                        <span class="extraction-count">抽出:\(extractionCount)</span>
                        <span class="error-count">エラー:\(errorCount)</span>
                    </div>
            """
            
            // 文字レベル精度を表示
            if characterAccuracy > 0 {
                let accuracyPercent = String(format: "%.1f", characterAccuracy * 100)
                fieldInfo += """
                    <div class="field-accuracy">文字精度:\(accuracyPercent)%</div>
                """
            }
            
            // 期待値を表示
            if let expected = expectedValue {
                fieldInfo += """
                    <div class="field-expected">期待値:\(expected)</div>
                """
            }
            
            fieldInfo += """
                </div>
                <div class="field-progress">
                    <div class="field-progress-fill" style="width: \(successRate * 100)%"></div>
                </div>
            </div>
            """
            
            return fieldInfo
        }.joined(separator: "")
        
        return fieldCards
    }
    
    /// note内容分析のHTMLを生成
    private static func generateNoteAnalysisHTML(_ noteAnalysis: NoteContentAnalysis) -> String {
        guard noteAnalysis.totalNoteExtractions > 0 else {
            return ""
        }
        
        let diversityScore = String(format: "%.2f", noteAnalysis.diversityScore)
        let mostCommonNote = noteAnalysis.mostCommonNote?.prefix(100) ?? "なし"
        
        return """
        <div class="note-analysis">
            <h4>📝 note内容分析</h4>
            <div class="note-metrics">
                <div class="note-metric">
                    <span class="note-label">多様性スコア:</span>
                    <span class="note-value">\(diversityScore)</span>
                </div>
                <div class="note-metric">
                    <span class="note-label">抽出数:</span>
                    <span class="note-value">\(noteAnalysis.totalNoteExtractions)</span>
                </div>
            </div>
            <div class="note-content">
                <div class="note-label">最頻出内容:</div>
                <div class="note-text">\(mostCommonNote)...</div>
            </div>
        </div>
        """
    }
    
    /// AI回答分析のHTMLを生成
    private static func generateAIResponseAnalysisHTML(_ aiAnalysis: AIResponseAnalysis) -> String {
        let insights = aiAnalysis.analysisInsights.replacingOccurrences(of: "\n", with: "<br>")
        
        var issuesHTML = ""
        if !aiAnalysis.mainIssues.isEmpty {
            issuesHTML = """
            <div class="ai-issues">
                <h5>主要な問題:</h5>
                <ul>
                    \(aiAnalysis.mainIssues.prefix(3).map { "<li>\($0)</li>" }.joined(separator: ""))
                </ul>
            </div>
            """
        }
        
        var patternsHTML = ""
        if !aiAnalysis.successPatterns.isEmpty {
            patternsHTML = """
            <div class="ai-patterns">
                <h5>成功パターン:</h5>
                <ul>
                    \(aiAnalysis.successPatterns.prefix(3).map { "<li>\($0)</li>" }.joined(separator: ""))
                </ul>
            </div>
            """
        }
        
        return """
        <div class="ai-analysis">
            <h4>🤖 AI回答分析</h4>
            <div class="ai-insights">\(insights)</div>
            \(issuesHTML)
            \(patternsHTML)
        </div>
        """
    }
    
    /// テスト名を取得
    private static func getTestName(testIndex: Int) -> String {
        let testNames = [
            "Chat Level 1 (Basic)",
            "Chat Level 2 (General)", 
            "Chat Level 3 (Complex)",
            "Contract Level 1 (Basic)",
            "Contract Level 2 (General)",
            "Contract Level 3 (Complex)",
            "Credit Card Level 1 (Basic)",
            "Credit Card Level 2 (General)",
            "Credit Card Level 3 (Complex)",
            "Voice Recognition Level 1 (Basic)",
            "Voice Recognition Level 2 (General)",
            "Voice Recognition Level 3 (Complex)",
            "Password Manager Level 1 (Basic)",
            "Password Manager Level 2 (General)",
            "Password Manager Level 3 (Complex)"
        ]
        
        return testNames.indices.contains(testIndex) ? testNames[testIndex] : "Test \(testIndex + 1)"
    }
}
