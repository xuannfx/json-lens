// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "JsonLens",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "JsonLensCore", targets: ["JsonLensCore"]),
        .executable(name: "JsonLens", targets: ["JsonLens"])
    ],
    targets: [
        .target(name: "JsonLensCore"),
        .executableTarget(
            name: "JsonLens",
            dependencies: ["JsonLensCore"]
        ),
        .testTarget(
            name: "JsonLensCoreTests",
            dependencies: ["JsonLensCore"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
