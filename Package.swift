// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkManager",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NetworkManager",
            targets: ["NetworkManager"]),
        
        .library(
            name: "NetworkManagerMock",
            targets: ["NetworkManagerMock"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/jogan1075/LoggerManager", from: "1.0.1"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
    
            .target(
                name: "NetworkManager",
                dependencies: [
                    "LoggerManager",
                ]
            ),
            .target(
                name: "NetworkManagerMock",
                dependencies: [
                    "NetworkManager",
                    .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
                ]
            )

    ]
)

//for target in package.targets {
//    target.swiftSettings = target.swiftSettings ?? []
//    target.swiftSettings?.append(
//        .unsafeFlags([
//            "-Xfrontend", "-warn-long-function-bodies=200", "-Xfrontend", "-warn-long-expression-type-checking=200",
//        ])
//    )
//}
