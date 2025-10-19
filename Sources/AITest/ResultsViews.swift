import SwiftUI

/// @ai[2025-01-19 01:00] 結果表示関連のビュー
/// 目的: ContentView.swiftの肥大化を防ぐため、結果表示関連のビューを分離
/// 背景: 複数の結果表示ビューがContentView.swiftに集約されていた
/// 意図: 保守性の向上とコードの整理

/// ベンチマーク結果表示ビュー
struct ResultsView: View {
    let results: [BenchmarkResult]
    
    var body: some View {
        List(results) { result in
            ResultRowView(result: result)
        }
        .navigationTitle("ベンチマーク結果")
    }
}

/// ベンチマーク結果行ビュー
struct ResultRowView: View {
    let result: BenchmarkResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.modelName)
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.2f", result.inferenceTime))ms")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("推論時間: \(String(format: "%.3f", result.inferenceTime))秒")
                    Text("総時間: \(String(format: "%.3f", result.totalTime))秒")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("メモリ: \(String(format: "%.1f", result.memoryUsage))MB")
                    Text("CPU: \(String(format: "%.1f", result.cpuUsage))%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// アカウント抽出結果表示ビュー
@available(iOS 26.0, macOS 26.0, *)
struct AccountResultsView: View {
    let results: [AccountExtractionResult]
    
    var body: some View {
        List(results) { result in
            AccountResultRowView(result: result)
        }
        .navigationTitle("アカウント抽出結果")
    }
}

/// アカウント抽出結果行ビュー
@available(iOS 26.0, macOS 26.0, *)
struct AccountResultRowView: View {
    let result: AccountExtractionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                
                Text("抽出結果")
                    .font(.headline)
                
                Spacer()
                
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let accountInfo = result.accountInfo {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = accountInfo.title {
                        Text("タイトル: \(title)")
                            .font(.caption)
                    }
                    if let userID = accountInfo.userID {
                        Text("ユーザーID: \(userID)")
                            .font(.caption)
                    }
                    if let password = accountInfo.password {
                        Text("パスワード: \(password)")
                            .font(.caption)
                    }
                    if let url = accountInfo.url {
                        Text("URL: \(url)")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            
            if let error = result.error {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

/// ベンチマークタイプ列挙型
enum BenchmarkType: String, CaseIterable {
    case general = "General"
    case account = "Account"
    
    var displayName: String {
        switch self {
        case .general:
            return "一般ベンチマーク"
        case .account:
            return "アカウント抽出ベンチマーク"
        }
    }
}

/// AIサポート状況表示ビュー
@available(iOS 26.0, macOS 26.0, *)
struct AISupportStatusView: View {
    let supportStatus: AISupportStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: supportStatus.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(supportStatus.isSupported ? .green : .red)
                
                Text("AIサポート状況")
                    .font(.headline)
            }
            
            if supportStatus.isSupported {
                Text("AI機能が利用可能です")
                    .foregroundColor(.green)
            } else {
                Text("AI機能が利用できません")
                    .foregroundColor(.red)
            }
            
            Text("ステータス: \(supportStatus.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
