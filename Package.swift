// swift-tools-version: 6.0

import PackageDescription

let package = Package(name: "unifi2mqtt",
                      platforms: [
                          .macOS(.v14),
                      ],
                      dependencies: [
                          .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.2.2")),
                          .package(url: "https://github.com/swift-server-community/mqtt-nio", .upToNextMajor(from: "2.8.0")),
                          .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.18.0"),
                          .package(url: "https://github.com/jollyjinx/JLog", .upToNextMajor(from: "0.0.5")),
                      ],
                      targets: [
                          .executableTarget(name: "unifi2mqtt",
                                            dependencies: [
                                                "UnifiLibrary",
                                                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                                                .product(name: "MQTTNIO", package: "mqtt-nio"),
                                                .product(name: "JLog", package: "JLog"),
                                            ]),
                          .target(name: "UnifiLibrary",
                                  dependencies: [
                                      .product(name: "JLog", package: "JLog"),
                                      .product(name: "AsyncHTTPClient", package: "async-http-client"),
                                  ]),
                      ])
