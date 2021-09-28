// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "core",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Core",
            targets: ["Core"]
        ),
    ],
    dependencies: [
        // NOTE: For some reason, this CasePaths dependency has to be declared without the ".git" extension.
        // - if the extension is present, the compilation of the package fails with "Missing module CasePaths"
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.7.0"),
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.4.0"),
        .package(name: "Overture", url: "https://github.com/pointfreeco/swift-overture.git", from: "0.5.0"),
        .package(name: "overture-operators", url: "https://github.com/Qase/swift-overture-operators.git", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Core",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                "CombineExt",
                "Overture",
                .product(name: "OvertureOperators", package: "overture-operators"),
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: [
                "Core",
                "CombineExt",
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
                "Overture",
                .product(name: "OvertureOperators", package: "overture-operators"),
            ]
        ),
    ]
)
