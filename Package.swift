// swift-tools-version:5.6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftHomePi",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
         .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
         .package(url: "https://github.com/pvieito/PythonKit", branch: "master"),
         .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
         .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
         .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
         .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0"),
         .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
         .package(url: "https://github.com/u5-03/SwiftHomeServerCore.git", from: "1.0.0"),
         .package(url: "git@github.com:u5-03/SwiftHomeCredentials.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .executableTarget(
            name: "SwiftHomePi",
            dependencies: [
                 .product(name: "SwiftyGPIO", package: "SwiftyGPIO"),
                 .product(name: "PythonKit", package: "PythonKit"),
                 .product(name: "Fluent", package: "fluent"),
                 .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                 .product(name: "Vapor", package: "vapor"),
                 .product(name: "Alamofire", package: "Alamofire"),
                 .product(name: "PathKit", package: "PathKit"),
                 .product(name: "SwiftHomeServerCore", package: "SwiftHomeServerCore"),
                 .product(name: "SwiftHomeCredentials", package: "SwiftHomeCredentials"),
            ],
            resources: [
                // Copy resource file to bundle
                .process("read_nfc.py"),
                .process("read_nfc_mock.py"),
                .process("warning_voice.mp3"),
            ]
        ),
        .testTarget(
            name: "SwiftHomePiTests",
            dependencies: ["SwiftHomePi"]),
    ]
)
