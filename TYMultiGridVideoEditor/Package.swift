// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TYMultiGridVideoEditor",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "TYMultiGridVideoEditor",
            targets: ["TYMultiGridVideoEditor"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TYMultiGridVideoEditor",
            path: "Sources",
            resources: [
                .process("TYMultiGridVideoEditor/Assets.xcassets"),
                .process("TYMultiGridVideoEditor/Preview Content")
            ]
        )
    ]
) 