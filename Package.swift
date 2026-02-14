// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeNotch",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/MrKai77/DynamicNotchKit", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "ClaudeNotch",
            dependencies: ["DynamicNotchKit"],
            path: "Sources/ClaudeNotch"
        ),
    ]
)
