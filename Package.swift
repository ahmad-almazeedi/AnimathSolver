// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AnimathSolver",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AnimathSolver",
            targets: ["AnimathSolver"]
        ),
    ],
    targets: [
        .target(
            name: "AnimathSolver",
            path: "Sources/AnimathSolver"
        ),
        .testTarget(
            name: "AnimathSolverTests",
            dependencies: ["AnimathSolver"],
            path: "Tests/AnimathSolverTests"
        ),
    ]
)
