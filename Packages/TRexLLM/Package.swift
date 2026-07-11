// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TRexLLM",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "TRexLLM",
            targets: ["TRexLLM"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/huggingface/AnyLanguageModel.git", from: "0.8.0")
    ],
    targets: [
        .target(
            name: "TRexLLM",
            dependencies: [
                .product(name: "AnyLanguageModel", package: "AnyLanguageModel")
            ]
        ),
        .testTarget(
            name: "TRexLLMTests",
            dependencies: [
                "TRexLLM",
                .product(name: "AnyLanguageModel", package: "AnyLanguageModel"),
            ]
        ),
    ]
)
