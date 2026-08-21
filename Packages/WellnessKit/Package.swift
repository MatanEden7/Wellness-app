// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WellnessKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "WellnessModels", targets: ["WellnessModels"]),
        .library(name: "WellnessDomain", targets: ["WellnessDomain"]),
        .library(name: "WellnessPersistence", targets: ["WellnessPersistence"]),
        .library(name: "WellnessServices", targets: ["WellnessServices"]),
        .library(name: "WellnessCatalog", targets: ["WellnessCatalog"]),
        .library(name: "WellnessStores", targets: ["WellnessStores"]),
        .library(name: "WellnessUI", targets: ["WellnessUI"]),
    ],
    targets: [
        // Foundation only — no SwiftUI, no SwiftData, no UIKit.
        .target(
            name: "WellnessModels",
            dependencies: []
        ),

        // Pure logic. Foundation + WellnessModels.
        // The port target for ~14,000 LOC of business logic.
        // Cannot import persistence — no generator can secretly query.
        .target(
            name: "WellnessDomain",
            dependencies: ["WellnessModels"]
        ),

        // Starter foods, exercises, recipes as JSON resources.
        .target(
            name: "WellnessCatalog",
            dependencies: ["WellnessModels"],
            resources: [.process("Resources")]
        ),

        // SwiftData lives here and only here.
        .target(
            name: "WellnessPersistence",
            dependencies: ["WellnessModels", "WellnessCatalog"]
        ),

        // Notifications, export, preferences, content language.
        .target(
            name: "WellnessServices",
            dependencies: ["WellnessModels", "WellnessDomain", "WellnessCatalog", "WellnessPersistence"]
        ),

        // @Observable feature stores — the only module that may hold mutable app state.
        .target(
            name: "WellnessStores",
            dependencies: ["WellnessModels", "WellnessDomain", "WellnessPersistence", "WellnessServices"]
        ),

        // Design system + shared components. SwiftUI, no domain logic, no persistence.
        .target(
            name: "WellnessUI",
            dependencies: ["WellnessModels", "WellnessDomain", "WellnessStores"],
            resources: [.process("Resources")]
        ),

        // --- Tests ---

        .testTarget(
            name: "WellnessCatalogTests",
            dependencies: ["WellnessCatalog", "WellnessModels"]
        ),
        .testTarget(
            name: "WellnessDomainTests",
            dependencies: ["WellnessDomain", "WellnessModels"]
        ),
        .testTarget(
            name: "WellnessPersistenceTests",
            dependencies: ["WellnessPersistence", "WellnessModels", "WellnessCatalog"]
        ),
        .testTarget(
            name: "WellnessServicesTests",
            dependencies: ["WellnessServices", "WellnessModels", "WellnessCatalog", "WellnessDomain", "WellnessPersistence"]
        ),
        .testTarget(
            name: "WellnessUITests",
            dependencies: ["WellnessUI"]
        ),
        .testTarget(
            name: "ParityTests",
            dependencies: ["WellnessDomain", "WellnessModels"],
            resources: [.copy("golden")]
        ),
    ]
)
