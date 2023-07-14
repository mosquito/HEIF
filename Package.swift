// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "HEIF",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/Bouke/Glob.git", from: "1.0.0"),
        .package(url: "https://github.com/jkandzi/Progress.swift.git", from: "0.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "HEIF",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Glob", package: "Glob"),
                .product(name: "Progress", package: "Progress.swift"),
            ]),
    ]
)
