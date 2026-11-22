// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacTeleprompter",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "MacTeleprompter", path: "Sources/MacTeleprompter")
    ]
)
