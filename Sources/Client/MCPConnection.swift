import Foundation
import MCP
import System
import SwiftAIAgent

enum MCPConnection {
    case mcpxcodebuild
    case github

    var gitHubToken: String {
        ProcessInfo.processInfo.environment["GitHubToken"] ?? ""
    }

    var headers: [String: String] {
        ["Authorization": "Bearer \(gitHubToken)"]
    }

    func connect() async throws {
        switch self {
        case .mcpxcodebuild:
            try await connectToLocalMCPServer()
        case .github:
            try await connectToGitHub()
        }
    }

    private func connectToGitHub() async throws {
        let transport = HTTPClientTransport(
            endpoint: URL(string: "https://api.githubcopilot.com/mcp/")!,
            headers: headers,
            streaming: true // Enable Server-Sent Events for real-time updates if supported
        )
        let client = Client(name: "SwiftAIAgent", version: "1.0.0")
        let result = try await client.connect(transport: transport)

        // Check server capabilities
        if result.capabilities.tools != nil {
            // Server supports tools (implicitly including tool calling if the 'tools' capability object is present)
        }
        let tools = try await client.listTools()
        print("Available tools: \(tools.tools.map { $0.name }.joined(separator: ", "))")
    }

    private func connectToLocalMCPServer() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "uvx") // Make sure uvx is available
        process.arguments = ["mcpxcodebuild"]

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe

        try process.run()
        let transport = StdioTransport(
            input: FileDescriptor(rawValue: outputPipe.fileHandleForReading.fileDescriptor),
            output: FileDescriptor(rawValue: inputPipe.fileHandleForWriting.fileDescriptor),
            logger: logger
        )
        let client = Client(name: "SwiftAIAgent", version: "1.0.0")
        let result = try await client.connect(transport: transport)

        // Check server capabilities
        if result.capabilities.tools != nil {
            // Server supports tools (implicitly including tool calling if the 'tools' capability object is present)
        }
        let tools = try await client.listTools()
        print("Available tools: \(tools.tools.map { $0.name }.joined(separator: ", "))")
    }
}
