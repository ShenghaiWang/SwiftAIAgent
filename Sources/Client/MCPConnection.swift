import Foundation
import GeminiSDK
import MCP
import SwiftAIAgent

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

struct MCPConnection {
    var gitHubToken: String {
        ProcessInfo.processInfo.environment["GitHubToken"] ?? ""
    }

    func run() async throws {
        let gemini = GeminiSDK(
            model: geminiModel,
            apiKey: geminiAPIKey)
        let gitHubURL = URL(string: "https://api.githubcopilot.com/mcp/")!
        let testAgent = try await AIAgent(
            title: "Draft article",
            model: gemini,
            mcpServers: [.http(url: gitHubURL, token: gitHubToken)],
            context: nil,
            instruction:
                """
                get all the tags of this repo https://github.com/ShenghaiWang/SwiftLlama
                """
        )
        let step = Workflow.Step.single(testAgent)
        let workflow = Workflow(step: step)
        let result = try await workflow.run(prompt: "start")
        print(result)
    }
}
