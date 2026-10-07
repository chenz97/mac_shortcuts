// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "FixedScroll",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "FixedScroll", targets: ["FixedScroll"])
  ],
  targets: [
    .target(name: "FixedScrollCore"),
    .target(
      name: "FixedScrollPlatform",
      dependencies: ["FixedScrollCore"]
    ),
    .executableTarget(
      name: "FixedScroll",
      dependencies: ["FixedScrollCore", "FixedScrollPlatform"]
    ),
    .testTarget(
      name: "FixedScrollCoreTests",
      dependencies: ["FixedScrollCore", "FixedScrollPlatform"]
    ),
  ]
)
