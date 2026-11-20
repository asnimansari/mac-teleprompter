// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "McTelep",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "McTelep", path: "Sources/McTelep")
    ]
)
