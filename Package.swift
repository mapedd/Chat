// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Chat",
  platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
  products: [
    .executable(name: "App", targets: ["App"]),
  ],
  dependencies: [
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    .package(url: "https://github.com/sliemeobn/elementary.git", from: "0.4.1"),
    .package(url: "https://github.com/sliemeobn/elementary-htmx.git", from: "0.3.0"),
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
    .package(url: "https://github.com/hummingbird-community/hummingbird-elementary.git", from: "0.4.0")
  ],
  targets: [
    .executableTarget(
      name: "App",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Hummingbird", package: "hummingbird"),
        .product(name: "Elementary", package: "elementary"),
        .product(name: "ElementaryHTMX", package: "elementary-htmx"),
        .product(name: "ElementaryHTMXSSE", package: "elementary-htmx"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "HummingbirdElementary", package: "hummingbird-elementary")
      ],
      resources: [
        .copy("Public"),
      ]
    ),
    .testTarget(
      name: "AppTests",
      dependencies: [
        .byName(name: "App"),
        .product(name: "HummingbirdTesting", package: "hummingbird")
      ],
      path: "Tests/AppTests"
    )
  ]
)
