import SwiftUI

/// @ai[2024-12-19 15:30] メインコンテンツビュー
/// Apple Intelligence Foundation Modelの性能測定UIを提供
@available(iOS 15.0, macOS 12.0, *)
struct ContentView: View {
    @StateObject private var benchmarkManager = BenchmarkManager()
    @State private var selectedTestType: TestType = .inferenceTime
    @State private var isRunning = false
    @State private var results: [BenchmarkResult] = []
    
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
                
                // テストタイプ選択
                Picker("Test Type", selection: $selectedTestType) {
                    ForEach(TestType.allCases, id: \.self) { testType in
                        Text(testType.displayName).tag(testType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
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
                    .background(isRunning ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isRunning)
                .padding(.horizontal)
                
                // 結果表示
                if !results.isEmpty {
                    ResultsView(results: results)
                }
                
                Spacer()
            }
            .navigationTitle("AITest")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    /// @ai[2024-12-19 15:30] ベンチマーク実行関数
    /// 選択されたテストタイプに基づいて性能測定を実行
    private func runBenchmark() {
        isRunning = true
        results = []
        
        Task {
            do {
                let newResults = try await benchmarkManager.runBenchmark(type: selectedTestType)
                await MainActor.run {
                    self.results = newResults
                    self.isRunning = false
                }
            } catch {
                await MainActor.run {
                    self.isRunning = false
                    // エラーハンドリング
                    print("Benchmark failed: \(error)")
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

#Preview {
    ContentView()
}
