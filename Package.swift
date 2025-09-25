// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AITest",
    platforms: [
        .iOS(.v18), // iOS 18+ for Apple Intelligence support
        .macOS(.v12) // macOS 12+ for development
    ],
    products: [
        .library(
            name: "AITest",
            targets: ["AITest"]
        )
    ],
    dependencies: [
        // Add dependencies here as needed
    ],
    targets: [
        .target(
            name: "AITest",
            dependencies: [],
            path: "Sources/AITest"
        ),
        .testTarget(
            name: "AITestTests",
            dependencies: ["AITest"],
            path: "Tests/AITestTests"
        )
    ]
)
