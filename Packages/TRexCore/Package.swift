// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

// MARK: - TesseractCore Force-Load Workaround
//
// This workaround is required for x86_64 (Intel Mac) support.
//
// Problem: The TesseractCore static library contains weak SIMD symbols that are not
// automatically linked when building for x86_64. This causes runtime crashes with
// "Symbol not found" errors on Intel Macs.
//
// Solution: Force-load the TesseractCore framework binary to ensure all symbols
// (including weak ones) are included in the final binary.
//
// Requirements:
// - TesseractSwift must be checked out at ../../../TesseractSwift relative to this package
// - The xcframework must be pre-built at TesseractSwift/Binaries/TesseractCore.xcframework
//
// Long-term: This should be replaced with a proper SPM binary target or by fixing
// the weak symbol linking in the TesseractSwift project.

private let tesseractCoreRelativePath = "../../../TesseractSwift/Binaries/TesseractCore.xcframework/macos-arm64_x86_64/TesseractCore.framework/TesseractCore"

private let tesseractCoreForceLoadPath: String = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent(tesseractCoreRelativePath)
    .standardized
    .path

let package = Package(
    name: "TRexCore",
    platforms: [.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TRexCore",
            targets: ["TRexCore"]
        ),
    ],
    dependencies: [
        .package(path: "../../../TesseractSwift"),
        .package(path: "../TRexLLM")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TRexCore",
            dependencies: ["TesseractSwift", "TRexLLM"],
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
