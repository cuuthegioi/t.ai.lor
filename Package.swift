// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tailor",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "Tailor", targets: ["Tailor"]),
    ],
    targets: [
        .executableTarget(
            name: "Tailor",
            path: "Sources/Tailor"
        ),
    ]
)
