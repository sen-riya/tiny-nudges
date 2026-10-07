// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TinyNudges",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "TinyNudges", path: "Sources/TinyNudges",
                          resources: [.copy("Resources")])
    ]
)
