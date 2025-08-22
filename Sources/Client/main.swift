import Foundation
import Logging

LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = .debug
    return handler
}

let geminiAPIKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
let geminiModel = "gemini-2.5-flash"
let geminiImageModel = "gemini-2.0-flash-preview-image-generation"
let geminiTTSModel = "gemini-2.5-flash-preview-tts"

// MCP connection example
//try await MCPConnection().run()

// Workflow example
//try await AgentWorkflow.manual.run()
try await AgentWorkflow.automatic.run()

// Tool calling example
//try await ToolCalling.run()

// Gemini Image Generation
//try await GminiImageGeneration.run()

// Gemini Speech Generation
//try await GminiSpeechGeneration.run()

// Google search tool
//try await GoogleSearchTool.run()

// Tool & MCP
//try await GoogleSearchTool.run()
