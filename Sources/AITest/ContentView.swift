import SwiftUI

/// @ai[2024-12-19 15:30] メインコンテンツビュー
/// Apple Intelligence Foundation Modelの性能測定UIを提供
@available(iOS 26.0, macOS 26.0, *)
struct ContentView: View {
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
        
        // ベンチマーク機能は削除されました
        Task {
            await MainActor.run {
                self.isRunning = false
                print("ℹ️ ベンチマーク機能は削除されました")
            }
        }
    }
}







@available(iOS 26.0, macOS 26.0, *)
#Preview {
    ContentView()
}
