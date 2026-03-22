// swift-tools-version: 6.0

import PackageDescription

let package = Package(name: "unifi2mqtt",
                      platforms: [
                          .macOS(.v15),
                      ],
                      dependencies: [
                          .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
                          .package(url: "https://github.com/swift-server-community/mqtt-nio.git", from: "2.12.0"),
                          .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.2"),
                          .package(url: "https://github.com/jollyjinx/JLog", .upToNextMajor(from: "0.0.7")),
                          .package(url: "https://github.com/jollyjinx/hetzner-dyndns-cgi", .upToNextMajor(from: "2.0.0")),
                      ],
                      targets: [
                          .executableTarget(name: "unifi2mqtt",
                                            dependencies: [
                                                "UnifiLibrary",
                                                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                                                .product(name: "MQTTNIO", package: "mqtt-nio"),
                                                .product(name: "JLog", package: "JLog"),
                                            ]),
                          .executableTarget(name: "unifimqtt2dns",
                                            dependencies: [
                                                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                                                .product(name: "HetznerDynDNS", package: "hetzner-dyndns-cgi"),
                                                .product(name: "MQTTNIO", package: "mqtt-nio"),
                                                .product(name: "JLog", package: "JLog"),
                                            ]),
                          .target(name: "UnifiLibrary",
                                  dependencies: [
                                      .product(name: "JLog", package: "JLog"),
                                      .product(name: "AsyncHTTPClient", package: "async-http-client"),
                                  ]),
                          .testTarget(name: "UnifiLibraryTests",
                                      dependencies: [
                                          "UnifiLibrary",
                                          .product(name: "JLog", package: "JLog"),
                                      ],
                                      resources: [
                                          .copy("Resources"),
                                      ]),
                      ])
