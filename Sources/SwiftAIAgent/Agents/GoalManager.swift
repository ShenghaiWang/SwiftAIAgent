import Foundation
import GeminiSDK
import AIAgentMacros

/// The actor managing goal
public actor GoalManager {
    public enum Error: Swift.Error {
        case noPlan
        case wrongResponseFormatFromAI
        case needClarification(questions: [String])
    }
    let aiagent: AIAgent
    let goal: String
    private(set) var clarifications: [String] = []

    private var clarifyInstructions: String {
            """
            <goal>\(goal)</goal>
            <clarifications>\(clarifications.joined(separator: "\n"))</clarifications>
            Is the above goal clear? Please ask for clarifications if needed.
            """
    }

    private var planInstructions: String {
            """
            <goal>\(goal)</goal>
            <clarifications>\(clarifications.joined(separator: "\n"))</clarifications>
            You are one excellent planner. 
            Please break this goal into tasks that suitalbe for AI Agents to execute.
            """
    }

    var gemini: GeminiSDK {
        GeminiSDK(model: "gemini-2.5-flash",
                  apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
    }

    /// Initialise a GoalManager
    /// Parameters:
    ///  - goal: The goal to achieve
    ///  - aiagent: The AI Agent to be responsible for clarifying goal, planning, orchestrating agent workflow.
    public init(goal: String,
                aiagent: AIAgent) {
        self.goal = goal
        self.aiagent = aiagent
    }

    /// Setup the workflow for the goal and run
    /// - Returns: The solution output from the agent for the goal
    /// - Throws: `GoalManager.Error.needClarification(questions: [String])` in case of needing clarification for the goal.
    /// - Throws: `Swift.Error` in case of any network error or LLM error.
    public func run() async throws -> AIAgentOutput {
        let clarification: AIGoalClarification = try await runAICommand(clarifyInstructions)
        if !clarification.questions.isEmpty {
            throw Error.needClarification(questions: clarification.questions)
        }
        let task: AITask = try await runAICommand(planInstructions)
        let workflow = try task.workflow(for: goal, with: gemini)
        return try await workflow.run(prompt: "kick off the task")
    }

    func plan() async throws -> AITask {
        let result = try await aiagent.run(prompt: planInstructions, outputSchema: AITask.self)
        if let task = result.result as? AITask {
            return task
        } else {
            throw Error.wrongResponseFormatFromAI
        }
    }

    func clarify() async throws -> AIGoalClarification {
        let result = try await aiagent.run(prompt: clarifyInstructions, outputSchema: AIGoalClarification.self)
        if let task = result.result as? AIGoalClarification {
            return task
        } else {
            throw Error.wrongResponseFormatFromAI
        }
    }

    private func runAICommand<T: AIModelOutput>(_ command: String) async throws -> T {
        let result = try await aiagent.run(prompt: command, outputSchema: T.self)
        if let task = result.result as? T {
            return task
        } else {
            throw Error.wrongResponseFormatFromAI
        }
    }

    /// Clarifiy the goal
    /// Parameters:
    ///  - clarifications: Clarifications
    public func set(clarifications: [String]) {
        self.clarifications.append(contentsOf: clarifications)
    }
}
