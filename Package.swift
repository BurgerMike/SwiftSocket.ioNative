// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSocket.ioNative",
    platforms: [.iOS(.v14), .macOS(.v13), .tvOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftSocket.ioNative",
            targets: ["SwiftSocket.ioNative"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftSocket.ioNative"),
        .testTarget(
            name: "SwiftSocket.ioNativeTests",
            dependencies: ["SwiftSocket.ioNative"]
        ),
    ]
)
