// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

private let tesseractCoreForceLoadPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("../../../TesseractSwift/Binaries/TesseractCore.xcframework/macos-arm64_x86_64/TesseractCore.framework/TesseractCore")
    .standardized
    .path

let package = Package(
    name: "TRexCore",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TRexCore",
            targets: ["TRexCore"]
        ),
    ],
    dependencies: [
        .package(path: "../../../TesseractSwift")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TRexCore",
            dependencies: ["TesseractSwift"],
            linkerSettings: [
                // Force-load the static TesseractCore archive so x86_64 picks up weak SIMD symbols.
                .unsafeFlags([
                    "-Xlinker", "-force_load",
                    "-Xlinker", tesseractCoreForceLoadPath
                ], .when(platforms: [.macOS]))
            ]
        ),
        .testTarget(
            name: "TRexCoreTests",
            dependencies: ["TRexCore"]
        ),
    ]
)
