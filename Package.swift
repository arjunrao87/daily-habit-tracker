// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cadence",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Cadence",
            targets: ["Cadence"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Cadence",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Sources/Cadence"
        ),
        .testTarget(
            name: "CadenceTests",
            dependencies: ["Cadence"],
            path: "Tests/CadenceTests"
        )
    ]
)
