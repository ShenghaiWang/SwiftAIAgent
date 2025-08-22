import AITools
import Foundation
import GeminiSDK
import SwiftAIAgent

struct AutoWorkflow {
    let model: AIAgentModel
    let managerAgent: AIAgent
    let goalManager: GoalManager

    static func run() async throws {
         let model = GeminiSDK(model: geminiModel, apiKey: geminiAPIKey)
         let autoWorkflow = try await AutoWorkflow(
             model: model,
             goal:
                 """
                 - Summarise AI history
                 - gemerate an image for the article
                 - save it in a markdow file 
                 """
         )
         try await autoWorkflow.runInternal()
     }

    init(model: AIAgentModel, goal: String) async throws {
        self.model = model
        self.managerAgent = try await AIAgent(title: "Manager", model: model)
        let baseFolder = "."
        let fileIO = FileIO(baseFolder: baseFolder)
        let cx = ProcessInfo.processInfo.environment["cx"] ?? ""
        let key = ProcessInfo.processInfo.environment["key"] ?? ""
        let gitHubURL = URL(string: "https://api.githubcopilot.com/mcp/")!
        let gitHubToken = ProcessInfo.processInfo.environment["GitHubToken"] ?? ""
        self.goalManager = GoalManager(
            goal: goal,
            managerAgent: managerAgent,
            models: [model],
            tools: [
                fileIO,
                GoogleSearch(cx: cx, key: key),
                Fetch(),
                GeminiImage(apiKey: geminiAPIKey, baseFolder: baseFolder),
            ],
            mcpServers: [.http(url: gitHubURL, token: gitHubToken)])
    }

    func runInternal() async throws {
        do {
            let result = try await goalManager.run()
            print(result)
        } catch {
            if case let GoalManager.Error.needClarification(questions) = error {
                print(
                    questions
                        .enumerated()
                        .map { "\($0 + 1): \($1)" }
                        .joined(separator: "\n"))
                let clarifications = readLine()
                await goalManager.set(clarifications: [clarifications ?? ""])
                try await runInternal()
            } else {
                print(error)
            }
        }
    }
}
