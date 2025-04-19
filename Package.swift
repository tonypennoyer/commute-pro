// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "commute_pro",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "commute_pro",
            targets: ["commute_pro"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0")
    ],
    targets: [
        .target(
            name: "commute_pro",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Shared"),
        .testTarget(
            name: "commute_proTests",
            dependencies: ["commute_pro"]),
    ]
) 