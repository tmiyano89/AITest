// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AITest",
        platforms: [
            .iOS(.v18), // iOS 18+ as minimum target
            // @ai[2024-12-19 17:00] ビルドエラー修正: .iOS(.v18_2) は存在しない
            // エラー: reference to member 'v18_2' cannot be resolved without a contextual type
            .macOS(.v15) // macOS 15+ as minimum target
            // @ai[2024-12-19 17:00] ビルドエラー修正: .macOS(.v15_0) は存在しない
            // エラー: reference to member 'v15_0' cannot be resolved without a contextual type
        ],
    products: [
        .library(
            name: "AITest",
            targets: ["AITest"]
        ),
        .executable(
            name: "AITestApp",
            targets: ["AITestApp"]
        )
    ],
    dependencies: [
        // FoundationModels is a system framework, no external dependency needed
    ],
    targets: [
        .target(
            name: "AITest",
            dependencies: [
                // FoundationModels is a system framework
            ],
            path: "Sources/AITest",
            resources: [
                .process("Prompts")
            ]
        ),
        .executableTarget(
            name: "AITestApp",
            dependencies: ["AITest"],
            path: "Sources/AITestApp",
            resources: [
                .process("TestData")
            ]
        ),
        .testTarget(
            name: "AITestTests",
            dependencies: ["AITest"],
            path: "Tests/AITestTests"
        )
    ]
)
