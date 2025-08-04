import Foundation
import Logging

LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = .debug
    return handler
}

// MCP connection example
//try await MCPConnection.github.connect()
//try await MCPConnection.mcpxcodebuild.connect()

// Workflow example
//try await AgentWorkflow.manual.run()
//try await AgentWorkflow.automatic.run()

// Tool calling example
//try await ToolCalling.run()

// Gemini Image Generation
//try await GminiImageGeneration.run()

// Gemini Speech Generation
try await GminiSpeechGeneration.run()
