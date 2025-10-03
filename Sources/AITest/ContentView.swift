import SwiftUI

/// @ai[2024-12-19 15:30] メインコンテンツビュー
/// Apple Intelligence Foundation Modelの性能測定UIを提供
@available(iOS 26.0, macOS 26.0, *)
struct ContentView: View {
    @StateObject private var benchmarkManager = BenchmarkManager()
    @StateObject private var accountBenchmark = AccountExtractionBenchmark()
    // @ai[2024-12-19 17:00] ビルドエラー修正: AISupportCheckerはiOS 26+でのみ利用可能
    // エラー: 'AISupportChecker' is only available in macOS 26.0 or newer
    // エラー: generic struct 'StateObject' requires that 'AISupportChecker?' conform to 'ObservableObject'
    @State private var aiSupportChecker: Any? = {
        if #available(iOS 26.0, macOS 26.0, *) {
            return AISupportChecker()
        } else {
            return nil
        }
    }()
    @State private var selectedTestType: TestType = .inferenceTime
    @State private var selectedBenchmarkType: BenchmarkType = .general
    @State private var isRunning = false
    @State private var results: [BenchmarkResult] = []
    @State private var accountResults: [AccountExtractionResult] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("AI Performance Test")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("iOS26 Apple Intelligence Foundation Model")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // ベンチマークタイプ選択
                Picker("Benchmark Type", selection: $selectedBenchmarkType) {
                    ForEach(BenchmarkType.allCases, id: \.self) { benchmarkType in
                        Text(benchmarkType.displayName).tag(benchmarkType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // テストタイプ選択（一般ベンチマークの場合のみ表示）
                if selectedBenchmarkType == .general {
                    Picker("Test Type", selection: $selectedTestType) {
                        ForEach(TestType.allCases, id: \.self) { testType in
                            Text(testType.displayName).tag(testType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                
                // AI利用可能性ステータス表示
                if #available(iOS 26.0, macOS 26.0, *) {
                    if let checker = aiSupportChecker as? AISupportChecker {
                        AISupportStatusView(supportStatus: checker.supportStatus)
                            .padding(.horizontal)
                    } else {
                        Text("AI機能チェック中...")
                            .foregroundColor(.orange)
                            .padding(.horizontal)
                    }
                } else {
                    // iOS 26未満の場合の代替表示
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("iOS 26+ または macOS 26+ が必要です")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // 性能測定ボタン
                Button(action: runBenchmark) {
                    HStack {
                        if isRunning {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isRunning ? "Running..." : "Start Benchmark")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? Color.gray : (getAISupportStatusFallback() ? Color.blue : Color.gray))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isRunning || !getAISupportStatusFallback())
                .padding(.horizontal)
                
                // 結果表示
                if !results.isEmpty || !accountResults.isEmpty {
                    if selectedBenchmarkType == .general {
                        ResultsView(results: results)
                    } else {
                        AccountResultsView(results: accountResults)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("AITest")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    @available(iOS 26.0, macOS 26.0, *)
    private func getAISupportStatus() -> AISupportStatus {
        if let checker = aiSupportChecker as? AISupportChecker {
            return checker.supportStatus
        }
        return .unsupportedOS
    }
    
    private func getAISupportStatusFallback() -> Bool {
        return getAISupportStatus().isSupported
    }
    
    /// @ai[2024-12-19 15:30] ベンチマーク実行関数
    /// 選択されたベンチマークタイプに基づいて性能測定を実行
    private func runBenchmark() {
        // AI利用可能性の事前チェック
        if let checker = aiSupportChecker as? AISupportChecker {
            guard checker.supportStatus.isSupported else {
                print("❌ AI機能が利用できません: \(checker.supportStatus.displayName)")
                return
            }
        } else {
            print("❌ AI機能チェッカーが利用できません")
            return
        }
        
        isRunning = true
        results = []
        accountResults = []
        
        Task {
            do {
                if selectedBenchmarkType == .general {
                    let newResults = try await benchmarkManager.runBenchmark(type: selectedTestType)
                    await MainActor.run {
                        self.results = newResults
                        self.isRunning = false
                    }
                } else {
                    // @ai[2024-12-19 18:30] concurrencyエラー修正: 直接実行
                    do {
                        try await accountBenchmark.runBenchmark()
                        await MainActor.run {
                            self.accountResults = accountBenchmark.results
                            self.isRunning = false
                        }
                    } catch {
                        await MainActor.run {
                            self.isRunning = false
                            print("❌ Account benchmark failed: \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isRunning = false
                    // エラーハンドリング
                    print("❌ Benchmark failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

/// @ai[2024-12-19 15:30] 結果表示ビュー
/// ベンチマーク結果を視覚的に表示
@available(iOS 15.0, macOS 12.0, *)
struct ResultsView: View {
    let results: [BenchmarkResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(results, id: \.id) { result in
                        ResultRowView(result: result)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

/// @ai[2024-12-19 15:30] 個別結果行ビュー
/// 各ベンチマーク結果の詳細を表示
@available(iOS 15.0, macOS 12.0, *)
struct ResultRowView: View {
    let result: BenchmarkResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.modelName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.2fms", result.inferenceTime))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Memory: \(String(format: "%.1f", result.memoryUsage))MB")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("CPU: \(String(format: "%.1f", result.cpuUsage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
}

/// @ai[2024-12-19 16:00] Account結果表示ビュー
/// Account情報抽出の結果を視覚的に表示
@available(iOS 26.0, macOS 26.0, *)
struct AccountResultsView: View {
    let results: [AccountExtractionResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Extraction Results")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(results, id: \.id) { result in
                        AccountResultRowView(result: result)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

/// @ai[2024-12-19 16:00] Account結果行ビュー
/// 各Account抽出結果の詳細を表示
@available(iOS 26.0, macOS 26.0, *)
struct AccountResultRowView: View {
    let result: AccountExtractionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Test \(result.id.uuidString.prefix(8))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if result.success {
                    Text("✅ Success")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("❌ Failed")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if let metrics = result.metrics {
                HStack {
                    Text("Time: \(String(format: "%.2f", metrics.extractionTime))s")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Memory: \(String(format: "%.1f", metrics.memoryUsed))MB")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Text("Fields: \(result.accountInfo?.extractedFieldsCount ?? 0)")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            
            if let error = result.error {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
}

/// ベンチマークタイプ
enum BenchmarkType: String, CaseIterable {
    case general = "General"
    case accountExtraction = "Account Extraction"
    
    var displayName: String {
        switch self {
        case .general:
            return "一般性能"
        case .accountExtraction:
            return "Account抽出"
        }
    }
}

/// AIサポートステータス表示ビュー
@available(iOS 26.0, macOS 26.0, *)
struct AISupportStatusView: View {
    let supportStatus: AISupportStatus
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            Text(supportStatus.displayName)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch supportStatus {
        case .checking:
            return "clock"
        case .supported:
            return "checkmark.circle.fill"
        case .unsupportedOS, .deviceNotEligible, .appleIntelligenceNotEnabled, .modelNotReady:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch supportStatus {
        case .checking:
            return .orange
        case .supported:
            return .green
        case .unsupportedOS, .deviceNotEligible, .appleIntelligenceNotEnabled, .modelNotReady:
            return .red
        case .error:
            return .red
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
#Preview {
    ContentView()
}
