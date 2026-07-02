// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Macopy",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Macopy", targets: ["Macopy"])
    ],
    targets: [
        .executableTarget(
            name: "Macopy",
            path: "Sources/Macopy",
            exclude: ["Info.plist"]
        )
    ]
)
