// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MrSpicyUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "MrSpicyUI", targets: ["MrSpicyUI"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MrSpicyUI",
            dependencies: [],
            path: ".",
            exclude: ["Tests"],
            sources: ["Sources"],
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Localization/en.lproj"),
                .process("Localization/ar.lproj")
            ]
        ),
        .testTarget(
            name: "MrSpicyUITests",
            dependencies: ["MrSpicyUI"],
            path: "Tests/MrSpicyUITests"
        )
    ]
)
