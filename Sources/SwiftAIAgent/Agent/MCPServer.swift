import Foundation
import MCP

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

public enum MCPServer: Sendable {
    case stdio(command: String, args: [String], description: String)
    case http(url: URL, token: String?, description: String)

    public var capabilityDescription: String {
        switch self {
            case let .stdio(_, _, description):
                return description
            case let .http(_, _, description):
                return description
        }
    }
}

extension MCPServer {
    private func transport() async throws -> Transport {
        switch self {
            case let .stdio(command, args, _):
                let process = Process()
                process.executableURL = URL(fileURLWithPath: command)  // Make sure uvx is available
                process.arguments = args

                let inputPipe = Pipe()
                let outputPipe = Pipe()
                process.standardInput = inputPipe
                process.standardOutput = outputPipe
                try process.run()

                return StdioTransport(
                    input: FileDescriptor(rawValue: outputPipe.fileHandleForReading.fileDescriptor),
                    output: FileDescriptor(rawValue: inputPipe.fileHandleForWriting.fileDescriptor),
                    logger: logger
                )
            case let .http(url, token, _):
                return HTTPClientTransport(
                    endpoint: url,
                    streaming: true
                ) { urlRequest in
                    guard let token else { return urlRequest }
                    var newUrlRequest = urlRequest
                    newUrlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    return newUrlRequest
                }
        }
    }

    func connect() async throws -> Client {
        let client = Client(name: "SwiftAIAgent", version: "1.0.0")
        try await client.connect(transport: try await transport())
        return client
    }
}

extension MCP.Tool {
    var toolDefinition: String {
        """
        {
            "name": "\(name)",
            "description": "\(description)",
            "parametersJsonSchema":  \(inputSchema.jsonSchema) 
        }
        """
    }
}

extension MCP.Value {
    var jsonSchema: String {
        switch self {
            case let .string(value): "\"" + value + "\""
            case let .array(values): "[" + values.map(\.jsonSchema).joined(separator: ",") + "]"
            case let .object(dict):
                #"""
                {
                        \#(dict.map { key, value in
                        """
                        "\(key)": \(value.jsonSchema)
                        """
                    }.joined(separator: ","))
                }
                """#
            case let .double(value): String(value)
            case let .int(value): String(value)
            case .null: "null"
            default:
                ""
        }
    }
}

extension Tool.Content {
    var aiAgentOutput: AIAgentOutput {
        switch self {
            case let .text(text): AIAgentOutput.text(text)
            case let .audio(data: data, mimeType: _):
                AIAgentOutput.audio(Data(base64Encoded: data) ?? Data())
            case let .image(data: data, mimeType: _, metadata: _):
                AIAgentOutput.image(Data(base64Encoded: data) ?? Data())
            case let .resource(uri: uri, mimeType: mimeType, text: text):
                .text("uri: \(uri)\n mimetype: \(mimeType)\n text: \(text ?? "")")
        }
    }
}
