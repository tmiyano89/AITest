import SwiftUI

/// @ai[2024-12-19 15:30] AITestアプリケーションのメインエントリーポイント
/// iOS26のApple Intelligence Foundation Modelの性能検証を目的としたアプリケーション
@available(iOS 15.0, macOS 12.0, *)
struct AITestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// @ai[2024-12-19 15:30] アプリケーションのエントリーポイント
/// テスト実行時は無効化される
#if !SWIFT_PACKAGE
@main
struct AITestMain {
    static func main() {
        AITestApp.main()
    }
}
#endif
