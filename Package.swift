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
      name: "CombineExtensions",
      targets: ["CombineExtensions"]
    ),
    .library(
      name: "CoreDatabase",
      targets: ["CoreDatabase"]
    ),
    .library(
      name: "Utils",
      targets: ["Utils"]
    ),
    .library(
      name: "ErrorReporting",
      targets: ["ErrorReporting"]
    ),
    .library(
      name: "KeyValueStorage",
      targets: ["KeyValueStorage"]
    ),
    .library(
      name: "ModelConvertible",
      targets: ["ModelConvertible"]
    ),
    .library(
      name: "Networking",
      targets: ["Networking"]
    ),
    .library(
      name: "NetworkMonitoring",
      targets: ["NetworkMonitoring"]
    ),
    .library(
      name: "RequestBuilder",
      targets: ["RequestBuilder"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.4.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.4.0"),
  ],
  targets: [
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
      name: "CoreDatabase",
      dependencies: [
        "CombineExtensions",
        "Utils",
        "ErrorReporting"
      ]
    ),
    .testTarget(
      name: "CoreDatabaseTests",
      dependencies: [
        "CoreDatabase"
      ]
    ),
    .target(
      name: "Utils",
      dependencies: [
      ]
    ),
    .testTarget(
      name: "UtilsTests",
      dependencies: [
        "Utils"
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
    .target(
      name: "ModelConvertible",
      dependencies: [
        "ErrorReporting",
      ]
    ),
    .testTarget(
      name: "ModelConvertibleTests",
      dependencies: [
        "ModelConvertible",
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
      ]
    ),
    .target(
      name: "Networking",
      dependencies: [
        "CombineExtensions",
        "ErrorReporting",
        "KeyValueStorage",
        "ModelConvertible",
        "NetworkMonitoring",
        "RequestBuilder",
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
      ]
    ),
    .testTarget(
      name: "NetworkingTests",
      dependencies: [
        "Networking",
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
      ]
    ),
    .target(
      name: "NetworkMonitoring",
      dependencies: [
        "CombineExtensions",
      ]
    ),
    .target(
      name: "RequestBuilder",
      dependencies: [
        "Utils",
        "ErrorReporting",
      ]
    ),
    .testTarget(
      name: "RequestBuilderTests",
      dependencies: [
        "RequestBuilder",
      ]
    )
  ]
)
