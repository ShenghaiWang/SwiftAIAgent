// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftAgent",
    platforms: [.macOS("13.0"),
                .macCatalyst("16.0"),
                .iOS("16.0"),
                .watchOS("9.0"),
                .tvOS("16.0"),
                .visionOS("1.0"),
    ],
    products: [
        .library(name: "SwiftAIAgent", targets: ["SwiftAIAgent"]),
        .library(name: "AIAgentMacros", targets: ["AIAgentMacros"]),
        .executable(name: "Client", targets: ["Client"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ShenghaiWang/swift-mcp-sdk.git", branch: "BearerAuthorization"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [.target(name: "SwiftAIAgent",
                      dependencies: ["AIAgentMacros",
                                     "GeminiSDK",
                                     .product(name: "MCP", package: "swift-mcp-sdk"),
                      ]),
              .target(name: "GeminiSDK",
                     dependencies: ["AIAgentMacros",
                     ]),
              .macro(name: "AIAgentMacroDefinitions",
                     dependencies: [.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                                    .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
                     ]),
              .target(name: "AIAgentMacros", dependencies: ["AIAgentMacroDefinitions"]),
              .testTarget(name: "AIAgentMacrosTests",
                          dependencies: ["AIAgentMacros",
                                         .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                                         .product(name: "SwiftParser", package: "swift-syntax"),
                          ]),
              .testTarget(name: "SwiftAIAgentTests",
                          dependencies: ["SwiftAIAgent"]),
              .testTarget(name: "GeminiSDKTests",
                          dependencies: ["AIAgentMacros",
                                         "GeminiSDK"]),
              .executableTarget(name: "Client",
                                dependencies: ["AIAgentMacros",
                                               "GeminiSDK",
                                               "SwiftAIAgent",
                                               .product(name: "MCP", package: "swift-mcp-sdk"),
                                              ]),
    ]
)
