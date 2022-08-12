// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Core",
  platforms: [
    .iOS(.v14),
    .macOS(.v11)
  ],
  products: [
    .library(
      name: "CoreToolkit",
      targets: ["CoreToolkit"]
    ),
    .library(
      name: "CombineExtensions",
      targets: ["CombineExtensions"]
    ),
    .library(
      name: "ErrorReporting",
      targets: ["ErrorReporting"]
    ),
    .library(
      name: "KeyValueStorage",
      targets: ["KeyValueStorage"]
    ),
  ],
  dependencies: [
    // NOTE: For some reason, this CasePaths dependency has to be declared without the ".git" extension.
    // - if the extension is present, the compilation of the package fails with "Missing module CasePaths"
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.7.0"),
    .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.4.0"),
  ],
  targets: [
    .target(
      name: "CoreToolkit",
      dependencies: [
      ]
    ),
    .testTarget(
      name: "CoreToolkitTests",
      dependencies: [
        "CoreToolkit"
      ]
    ),
    .target(
      name: "CombineExtensions",
      dependencies: [
        "ErrorReporting"
      ]
    ),
    .testTarget(
      name: "CombineExtensionsTests",
      dependencies: [
        "CombineExtensions",
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
      ]
    ),
    .target(
      name: "ErrorReporting",
      dependencies: [
      ]
    ),
    .testTarget(
      name: "ErrorReportingTests",
      dependencies: [
        "ErrorReporting"
      ]
    ),
    .target(
      name: "KeyValueStorage",
      dependencies: [
        "CombineExtensions",
        "ErrorReporting",
      ]
    ),
    .testTarget(
      name: "KeyValueStorageTests",
      dependencies: [
        "KeyValueStorage",
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
      ]
    ),
  ]
)
