// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Reminder",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Reminder", path: "Sources/Reminder",
                          resources: [.process("Resources")])
    ]
)
