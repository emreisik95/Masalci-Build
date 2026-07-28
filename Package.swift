// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MasalciCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MasalciCore", targets: ["MasalciCore"]),
        .executable(name: "MasalciCoreChecks", targets: ["MasalciCoreChecks"]),
    ],
    targets: [
        .target(
            name: "MasalciCore",
            path: "Targets/App/Sources/Core"
        ),
        .executableTarget(
            name: "MasalciCoreChecks",
            dependencies: ["MasalciCore"],
            path: "Targets/App/Checks"
        ),
        .testTarget(
            name: "MasalciCoreTests",
            dependencies: ["MasalciCore"],
            path: "Targets/App/Tests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
