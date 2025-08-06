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
    let managerAgent: AIAgent
    let goal: String
    let models: [AIAgentModel]
    let tools: [any AIAgentTool]
    let mcpServers: [any MCPServer]

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

    /// Initialise a GoalManager
    /// - Parameters:
    ///  - goal: The goal to achieve
    ///  - managerAgent: The AI Agent to be responsible for clarifying goal, planning, orchestrating agent workflow.
    ///  - models: The Models that can be used to setup agents and workflow
    ///  - tools: The tools can be used by this agent
    ///  - mcpServers: The MCP server can be used by this agent
    public init(goal: String,
                managerAgent: AIAgent,
                models: [AIAgentModel],
                tools: [any AIAgentTool] = [],
                mcpServers: [any MCPServer] = []) {
        self.goal = goal
        self.managerAgent = managerAgent
        self.models = models
        self.tools = tools
        self.mcpServers = mcpServers
    }

    /// Setup the workflow for the goal and run
    /// - Returns: The solution output from the agent for the goal
    /// - Throws: `GoalManager.Error.needClarification(questions: [String])` in case of needing clarification for the goal.
    /// - Throws: `Swift.Error` in case of any network error or LLM error.
    public func run() async throws -> [AIAgentOutput] {
        let clarification: AIGoalClarification = try await runAICommand(clarifyInstructions)
        if !clarification.questions.isEmpty {
            throw Error.needClarification(questions: clarification.questions)
        }
        let task: AITask = try await runAICommand(planInstructions)
        let workflow = try task.workflow(for: goal,
                                         models: models,
                                         tools: tools,
                                         mcpServers: mcpServers)
        return try await workflow.run(prompt: "kick off the task")
    }

    private func runAICommand<T: AIModelOutput>(_ command: String) async throws -> T {
        let result = try await managerAgent.run(prompt: command, outputSchema: T.self)
        if case let .strongTypedValue(result) = result.allStrongTypedValues.first,
           let task = result as? T {
            return task
        } else {
            throw Error.wrongResponseFormatFromAI
        }
    }

    /// Clarifiy the goal
    /// - Parameters:
    ///  - clarifications: Clarifications
    public func set(clarifications: [String]) {
        self.clarifications.append(contentsOf: clarifications)
    }
}
