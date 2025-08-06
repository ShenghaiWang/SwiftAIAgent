import Foundation
import GeminiSDK
import SwiftAIAgent
import AITools

enum AgentWorkflow {
    case manual
    case automatic

    func run() async throws {
        switch self {
        case .manual:
            try await runManualFlow()
        case .automatic:
            try await runAutomaticFlow()
        }
    }

    struct AutoWorkflow {
        let model: AIAgentModel
        let managerAgent: AIAgent
        let goalManager: GoalManager

        init(model: AIAgentModel, goal: String) {
            self.model = model
            self.managerAgent = AIAgent(title: "Manager", model: model)
            let fileIO = FileIO(baseFolder: ".")
            self.goalManager = GoalManager(goal: goal,
                                           managerAgent: managerAgent,
                                           models: [model],
                                           tools: [fileIO])
        }

        func run() async throws {
            do {
                let result = try await goalManager.run()
                print(result)
            } catch {
                if case let GoalManager.Error.needClarification(questions) = error {
                    print(questions
                        .enumerated()
                        .map { "\($0 + 1): \($1))" }
                        .joined(separator: "\n"))
                    let clarifications = readLine()
                    await goalManager.set(clarifications: [clarifications ?? ""])
                    try await run()
                } else {
                    print(error)
                }
            }
        }
    }

    private func runManualFlow() async throws {
        let gemini = GeminiSDK(model: "gemini-2.5-flash",
                               apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")

        let context = AIAgentContext("""
                                 The task is to write an essay about the history of AI.
                                 A few agents work on this task.
                                 """)

        let draftAgent = AIAgent(title: "Draft article",
                                 model: gemini,
                                 context: context,
                                 instruction: """
                                 You are an expert in writing articles based on your knowledge.
                                 """)
        let reviewAgent = AIAgent(title: "Review",
                                  model: gemini,
                                  context: context,
                                  instruction: """
                                You are an expert in reviewing articles. Please review and improve the article you are given.
                                """)
        let finaliserAgent = AIAgent(title: "Finaliser",
                                     model: gemini,
                                     tools: [FileIO(baseFolder: ".")],
                                     context: context,
                                     instruction: """
                                You are an expert in finialising articles. Please finalise the article based on the draft and review. 
                                Save it in article.md file eventually."
                                """)

        await finaliserAgent.add(input: draftAgent.id)
        let draftStep = Workflow.Step.single(draftAgent)
        let reviewStep = Workflow.Step.single(reviewAgent)
        let finaliseStep = Workflow.Step.single(finaliserAgent)
        let workflow = Workflow(step: .sequence([draftStep, reviewStep, finaliseStep]))

        let result = try await workflow.run(prompt: "Let's write this artile")
        print(result.allTexts)
    }

    private func runAutomaticFlow() async throws {
        let model = GeminiSDK(model: "gemini-2.5-flash", apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
        let autoWorkflow = AutoWorkflow(model: model,
                                        goal:
            """
            Summarise hidden gem features in Kotlin language and showcase their usage with examples.
            save it in a markdown file.
            """
            )
        try await autoWorkflow.run()
    }
}
