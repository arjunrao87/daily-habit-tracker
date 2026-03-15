// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DailyHabitTracker",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DailyHabitTracker",
            targets: ["DailyHabitTracker"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "DailyHabitTracker",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Sources/DailyHabitTracker"
        ),
        .testTarget(
            name: "DailyHabitTrackerTests",
            dependencies: ["DailyHabitTracker"],
            path: "Tests/DailyHabitTrackerTests"
        )
    ]
)
