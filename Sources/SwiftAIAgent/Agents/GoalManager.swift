import AIAgentMacros
import Foundation
import GeminiSDK

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
    let mcpServers: [MCPServer]

    private(set) var clarifications: [String] = []

    private var clarifyInstructions: String {
        """
        <goal>\(goal)</goal>
        <clarifications>\(clarifications.joined(separator: "\n"))</clarifications>
        Is the above goal clear? Please ask for clarifications if needed.
        Ignore the tools/function calls at this stage. 
        Returns questions that need to be asked in the specified json schema.
        """
    }

    private var planInstructions: String {
        """
        <goal>\(goal)</goal>
        <clarifications>\(clarifications.joined(separator: "\n"))</clarifications>
        You are one excellent planner. 
        Please break this goal into tasks that suitalbe for AI Agents to execute.
        You can also assign the following tools to agents if needed.
        There might be multiple tools that can achive the same goal, 
        use your best judgement to assign the best suitable tools to the agents.
        <avaialbleTools>\(tools.toolDefinitions.joined(separator: ","))</avaialbleTools>
        """
    }

    /// Initialise a GoalManager
    /// - Parameters:
    ///  - goal: The goal to achieve
    ///  - managerAgent: The AI Agent to be responsible for clarifying goal, planning, orchestrating agent workflow.
    ///  - models: The Models that can be used to setup agents and workflow
    ///  - tools: The tools can be used by this agent
    ///  - mcpServers: The MCP server can be used by this agent
    public init(
        goal: String,
        managerAgent: AIAgent,
        models: [AIAgentModel],
        tools: [any AIAgentTool] = [],
        mcpServers: [MCPServer] = []
    ) {
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
    public func run(noFutherClarification: Bool = false) async throws -> [AIAgentOutput] {
        if !noFutherClarification {
            logger.debug("\n===Checking Goal===\n")
            let clarifications = try await clarify()
            logger.debug("\n===Clarification Questions===\n\(clarifications)\n")
            if !clarifications.isEmpty {
                throw Error.needClarification(questions: clarifications)
            }
        }
        logger.debug("\n===Starting Planning===\n")
        let task: AITask = try await runAICommand(planInstructions)
        logger.debug("\n===Tasks planned===\n\(task)\n")
        let workflow = try await workflow(for: task)
        logger.debug("\n===Workflow Planned===\n\(workflow)\n")
        return try await workflow.run(prompt: "kick off the task")
    }

    /// Clarify the goal
    /// - Returns: The calriciation questions for the goal
    /// - Throws: `Swift.Error` in case of any network error or LLM error.
    public func clarify() async throws -> [String] {
        logger.debug("\n===Checking Goal===\n")
        let clarification: AIGoalClarification = try await runAICommand(clarifyInstructions)
        logger.debug("\n===Clarification Questions===\n\(clarification)\n")
        return clarification.questions
    }

    private func runAICommand<T: AIModelSchema>(_ command: String) async throws -> T {
        let result = try await managerAgent.run(prompt: command, outputSchema: T.self)
        if case let .strongTypedValue(result) = result.allStrongTypedValues.first,
            let task = result as? T
        {
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

    private func workflow(for task: AITask) async throws -> Workflow {
        guard let subTasks = task.subTasks,
            let model = models.first
        else {  // TODO: select model based on planning
            throw GoalManager.Error.noPlan
        }

        var agentIds: [UUID] = []
        var steps: [Workflow.Step] = []
        for subtask in subTasks {
            // TODO: Smarter workflow generation, sequence or paralletl? tools/mcpserver assignment etc.
            let context = AIAgentContext(
                """
                <finalGoal>\(self.goal)</finalGoal>
                <agentSetup>\(task.agentSetup)</agentSetup>
                You are agent `\(subtask.name)` and your goal is `\(subtask.details)`
                """
            )
            let taskTools: [AIAgentTool] =
                if let subTaskTool = subtask.tools {
                    tools.filter { !Set($0.methodMap.keys).intersection(Set(subTaskTool)).isEmpty }
                } else {
                    []
                }
            let taskMCPServers: [MCPServer] = []  // TODO: refine mcp servers
            let agent = try await AIAgent(
                title: subtask.name,
                model: model,
                tools: taskTools,
                mcpServers: taskMCPServers,
                context: context,
                instruction: subtask.details)
            // TODO: refine input flow
            for id in agentIds.dropLast() {
                await agent.add(input: id)
            }
            agentIds.append(agent.id)
            // TODO: Adjust data flow input if needed
            steps.append(Workflow.Step.single(agent))
        }
        return Workflow(step: .sequence(steps))
    }
}

extension AITask {
    var agentSetup: String {
        """
        There are \(subTasks?.count ?? 0) agents to work collaboratively on this goal.
        \((subTasks ?? []).enumerated().map({ index, agent in
            "<agent \(index + 1)>name: \(agent.name) \ntask:\(agent.details)</agent \(index + 1)>"
        }).joined(separator: "\n"))
        """
    }
}
