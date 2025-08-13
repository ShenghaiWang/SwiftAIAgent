import Foundation
import AIAgentMacros
import GeminiSDK
import SwiftAIAgent

enum ToolCalling {
    @AITool
    struct ToolStruct {
        /// Get weather of the city
        /// - Parameters:
        ///  - city: The city
        /// - Returns: Weather of the city
        func getWeather(city: String) -> String {
            "It's raining in Sydney"
        }
    }

    static func run() async throws {
        let gemini = GeminiSDK(model: geminiModel,
                               apiKey: geminiAPIKey)
        let context = AIAgentContext("Get weather")
        let agent = try await AIAgent(title: "Weahter Agent",
                                      model: gemini,
                                      tools: [ToolStruct()],
                                      context: context,
                                      instruction: "")
        let result = try await agent.run(prompt: "Get weather for Sydney")
        print(result)
    }
}
