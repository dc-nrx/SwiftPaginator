// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPaginator",
	platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(
            name: "SwiftPaginator",
            targets: ["SwiftPaginator"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftPaginator",
            dependencies: []),
        .testTarget(
            name: "SwiftPaginatorTests",
            dependencies: ["SwiftPaginator"]),
    ]
)
