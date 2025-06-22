// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MultiGridVideoEditor",
    platforms: [
        .macOS(.v12) // Specify macOS 12.0 or newer
    ],
    products: [
        .executable(
            name: "MultiGridVideoEditor",
            targets: ["MultiGridVideoEditor"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MultiGridVideoEditor",
            path: "." // All source files are in the root directory
        )
    ]
) 