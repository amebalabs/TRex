// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
        .package(url: "https://github.com/amebalabs/TesseractSwift.git", from: "1.2.0"),
        .package(path: "../TRexLLM")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TRexCore",
            dependencies: ["TesseractSwift", "TRexLLM"],
            linkerSettings: [
                .linkedLibrary("curl"),
                .linkedLibrary("z")
            ]
        ),
        .testTarget(
            name: "TRexCoreTests",
            dependencies: ["TRexCore"]
        ),
    ]
)
