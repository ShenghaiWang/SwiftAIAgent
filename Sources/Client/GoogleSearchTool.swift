import GeminiSDK
import SwiftAIAgent
import AITools
import Foundation
import SwiftAIAgent

struct GoogleSearchTool {
    static func run() async throws {
        let gemini = GeminiSDK(model: geminiModel,
                               apiKey: geminiAPIKey)
        let cx = ProcessInfo.processInfo.environment["cx"] ?? ""
        let key = ProcessInfo.processInfo.environment["key"] ?? ""
        let draftAgent = try await AIAgent(title: "Draft article",
                                           model: gemini,
                                           tools: [GoogleSearch(cx: cx, key: key)],
                                           context: nil,
                                           instruction:
                         """
                         * Search "Computer science" using search tool
                         """
        )
        let step = Workflow.Step.single(draftAgent)
        let workflow = Workflow(step: step)
        let result = try await workflow.run(prompt: "start")
        print(result)
    }
}
