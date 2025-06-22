// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TYMultiGridVideoEditor",
    platforms: [
        .macOS(.v12) // Specify macOS 12.0 or newer
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
            path: "." // All source files are in the root directory
        )
    ]
) 