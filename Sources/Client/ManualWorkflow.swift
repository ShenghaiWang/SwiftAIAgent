import AITools
import Foundation
import GeminiSDK
import SwiftAIAgent

struct ManualFlow {
    static func run() async throws {
        let gemini = GeminiSDK(model: geminiModel, apiKey: geminiAPIKey)

        let context = AIAgentContext(
            """
            The task is to write an essay about the history of AI.
            A few agents work on this task.
            """
        )

        let draftAgent = try await AIAgent(
            title: "Draft article",
            model: gemini,
            context: context,
            instruction: """
                You are an expert in writing articles based on your knowledge.
                """
        )
        let reviewAgent = try await AIAgent(
            title: "Review",
            model: gemini,
            context: context,
            instruction: """
                You are an expert in reviewing articles. Please review and improve the article you are given.
                """
        )
        let finaliserAgent = try await AIAgent(
            title: "Finaliser",
            model: gemini,
            tools: [FileIO(baseFolder: ".")],
            context: context,
            instruction: """
                You are an expert in finialising articles. Please finalise the article based on the draft and review. 
                Save it in article.md file eventually."
                """
        )

        await finaliserAgent.add(input: draftAgent.id)
        let draftStep = Workflow.Step.single(draftAgent)
        let reviewStep = Workflow.Step.single(reviewAgent)
        let finaliseStep = Workflow.Step.single(finaliserAgent)
        let workflow = Workflow(step: .sequence([draftStep, reviewStep, finaliseStep]))

        let result = try await workflow.run(prompt: "Let's write this artile")
        print(result.allTexts)
    }
}
