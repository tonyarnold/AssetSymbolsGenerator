// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AssetSymbolsGenerator",
    platforms: [
        .macOS(.v14),
        .macCatalyst(.v15),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .executable(
            name: "AssetSymbolsGenerator",
            targets: ["AssetSymbolsGenerator"]
        ),
        .plugin(
            name: "AssetSymbolsGeneratorBuildToolPlugin",
            targets: ["AssetSymbolsGeneratorBuildToolPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-format.git", from: "510.1.0")
    ],
    targets: [
        .executableTarget(
            name: "AssetSymbolsGenerator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftFormat", package: "swift-format")
            ]
        ),

        .plugin(
            name: "AssetSymbolsGeneratorBuildToolPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "AssetSymbolsGenerator")
            ]
        )
    ]
)
