import GeminiSDK
import SwiftAIAgent
import AITools
import Foundation
import SwiftAIAgent

struct GoogleSearchTool {
    static func run() async throws {
        let gemini = GeminiSDK(model: "gemini-2.5-flash",
                               apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
        let cx = ProcessInfo.processInfo.environment["cx"] ?? ""
        let key = ProcessInfo.processInfo.environment["key"] ?? ""
        let draftAgent = AIAgent(title: "Draft article",
                                 model: gemini,
                                 tools: [GoogleSearch(cx: cx, key: key)],
                                 context: nil,
                                 instruction: """
                         Search "AI" using search  tool
                         """
        )
        let step = Workflow.Step.single(draftAgent)
        let workflow = Workflow(step: step)
        let result = try await workflow.run(prompt: "start")
        print(result)
    }
}
