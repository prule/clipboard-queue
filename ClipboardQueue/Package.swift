// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClipboardQueue",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClipboardQueue",
            path: "Sources/ClipboardQueue"
        )
    ]
)
