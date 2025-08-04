import Foundation
import GeminiSDK
import SwiftAIAgent

enum AgentWorkflow {
    case manual
    case automatic

    func run() async throws {
        switch self {
        case .manual:
            try await runManualFlow()
        case .automatic:
            try await ruanAutomaticFlow()
        }
    }

    struct AutoWorkflow {
        let model: AIAgentModel
        let managerAgent: AIAgent
        let goalManager: GoalManager

        init(model: AIAgentModel, goal: String) {
            self.model = model
            self.managerAgent = AIAgent(title: "Manager", model: model)
            self.goalManager = GoalManager(goal: goal, aiagent: managerAgent)
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
                                     context: context,
                                     instruction: """
                                You are an expert in finialising articles. Please finalise the article based on the draft and review
                                """)

        await finaliserAgent.add(input: draftAgent.id)
        let draftStep = Workflow.Step.single(draftAgent)
        let reviewStep = Workflow.Step.single(reviewAgent)
        let finaliseStep = Workflow.Step.single(finaliserAgent)
        let workflow = Workflow(step: .sequence([draftStep, reviewStep, finaliseStep]))

        let result = try await workflow.run(prompt: "Let's write this artile")
        print(result.allTexts)
    }

    private func ruanAutomaticFlow() async throws {
        let model = GeminiSDK(model: "gemini-2.5-flash", apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
        let autoWorkflow = AutoWorkflow(model: model, goal: "Write an article about history of AI and output it in markdown format")
        try await autoWorkflow.run()
    }
}
