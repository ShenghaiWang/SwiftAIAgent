import AIAgentMacros
import Foundation
import GeminiSDK

/// The actor managing goal execution through planning, clarification, and orchestration
public actor GoalManager {
    // MARK: - Configuration
    let managerAgent: AIAgent
    let goal: String
    let models: [AIAgentModel]
    let tools: [any AIAgentTool]
    let mcpServers: [MCPServer]

    // MARK: - State
    private(set) var clarifications: [String] = []
    private(set) var currentPlan: AITask?
    private(set) var executionState: ExecutionState = .idle
    private let configuration: Configuration

    // MARK: - Instruction Templates
    private var clarifyInstructions: String {
        """
        <goal>\(goal)</goal>
        <current_time>\(Date().ISO8601Format())</current_time>
        <clarifications>\(clarifications.joined(separator: "\n"))</clarifications>

        Analyze the above goal and determine if it's clear enough for execution.
        Consider the following aspects:
        - Is the objective well-defined?
        - Are there any ambiguous terms or requirements?
        - Is the scope appropriate for AI agent execution?
        - Are there missing dependencies or constraints?

        If clarification is needed, ask specific, actionable questions.
        Ignore tools/function calls at this stage - focus only on goal clarity.
        Return your questions in the specified JSON schema.
        """
    }

    private var strategyInstructions: String {
        """
        <goal>\(goal)</goal>
        <clarifications>\(clarifications.joined(separator: "\n"))</clarifications>

        Please decide the best strategy to achieve the above goal.

        Some example strategies are:
        - Reflection Strategy
        - Iterative Refinement Strategy
        - Divide and Conquer Strategy  
        - Validation and Quality Assurance Strategy
        - Adaptive Strategy Selection

        Please note, you are not limited to use these strategies, feel free to use any strategies that are proper. 
        Determine the best strategy for the goal based on your best knowledge.
        """
    }

    private var planInstructions: String {
        """
        <goal>\(goal)</goal>
        <clarifications>\(clarifications.joined(separator: "\n"))</clarifications>

        You are an expert task planner with strategic thinking capabilities. 
        Break this goal into executable subtasks for AI agents using the planning strategies specified.

        ## Core Planning Guidelines:
        - Create atomic, well-defined subtasks with clear success criteria
        - Consider dependencies between tasks and optimal execution order
        - Assign appropriate tools based on task requirements
        - Set reasonable temperature values based on creativity needs (0.0-1.0)
        - Determine if tasks can run in parallel or must be sequential

        ## Tool and Resource Assignment:
        Available Tools:
        \(tools.toolDefinitions.joined(separator: "\n"))

        Available MCP Server Capabilities:
        \(mcpServers.map(\.capabilityDescription).joined(separator: "\n"))

        ## Temperature Guidelines:
        - **0.0-0.3**: Factual, analytical, or precise tasks
        - **0.4-0.6**: Balanced reasoning and creativity
        - **0.7-1.0**: Creative, exploratory, or brainstorming tasks

        Use the specified JSON schema for your response.
        """
    }

    /// Initialize a GoalManager
    /// - Parameters:
    ///   - goal: The goal to achieve
    ///   - managerAgent: The AI Agent responsible for clarifying goals, planning, and orchestrating workflows
    ///   - models: Available models for setting up agents and workflows
    ///   - tools: Available tools for agent execution
    ///   - mcpServers: Available MCP servers for agent execution
    ///   - configuration: Configuration options for goal management
    /// - Throws: `Error.invalidConfiguration` if the configuration is invalid
    public init(
        goal: String,
        managerAgent: AIAgent,
        models: [AIAgentModel],
        tools: [any AIAgentTool] = [],
        mcpServers: [MCPServer] = [],
        configuration: Configuration = Configuration()
    ) throws {
        guard !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Error.invalidConfiguration("Goal cannot be empty")
        }

        guard !models.isEmpty else {
            throw Error.invalidConfiguration("At least one model must be provided")
        }

        self.goal = goal
        self.managerAgent = managerAgent
        self.models = models
        self.tools = tools
        self.mcpServers = mcpServers
        self.configuration = configuration
    }

    /// Execute the complete goal management workflow
    /// - Parameters:
    ///   - skipClarification: Whether to skip the clarification phase
    /// - Returns: The execution results from all agents
    /// - Throws: Various errors including clarification needs, planning failures, or execution errors
    public func run(skipClarification: Bool = false) async throws -> [AIAgentOutput] {
        do {
            executionState = .clarifying

            if !skipClarification {
                logger.debug("\n=== Goal Clarification Phase ===\n")
                let clarificationQuestions = try await clarify()
                logger.debug("Clarification questions: \(clarificationQuestions)")

                if !clarificationQuestions.isEmpty {
                    executionState = .idle
                    throw Error.needClarification(questions: clarificationQuestions)
                }
            }

            executionState = .planning
            logger.debug("\n=== Planning Phase ===\n")
            let task = try await plan()
            currentPlan = task
            logger.debug("Generated plan: \(task)")

            executionState = .executing
            logger.debug("\n=== Execution Phase ===\n")
            let results = try await execute(task: task)

            executionState = .completed
            logger.debug("Execution completed successfully")
            return results
        } catch {
            executionState = .failed(error as? Error ?? .executionFailed(error.localizedDescription))
            logger.error("Goal execution failed: \(error)")
            throw error
        }
    }

    /// Analyze the goal and identify clarification needs
    /// - Returns: Array of clarification questions (empty if goal is clear)
    /// - Throws: Network or LLM errors
    public func clarify() async throws -> [String] {
        logger.debug("Analyzing goal for clarity...")
        let clarification: AIGoalClarification = try await runAICommand(clarifyInstructions)
        logger.debug("Clarification analysis complete: \(clarification.questions.count) questions")
        return clarification.questions
    }

    /// Generate an execution plan for the goal
    /// - Returns: Structured task plan with subtasks and resource assignments
    /// - Throws: Planning or LLM errors
    public func plan() async throws -> AITask {
        let strategy = try await makeStrategy()

        logger.debug("Generating execution plan...")
        let task: AITask = try await runAICommand(planInstructions + "\n<strategy>\(strategy)</strategy>")

        try validatePlan(task)

        logger.debug("Plan generated successfully with \(task.subTasks?.count ?? 0) subtasks")
        return task
    }

    private func makeStrategy() async throws -> String {
        logger.debug("Generating strategy...")
        let strategy: AIStrategy = try await runAICommand(strategyInstructions)

        logger.debug("Generated strategy: \(strategy.details)")
        return strategy.details
    }

    /// Execute the planned task workflow
    /// - Parameter task: The task plan to execute
    /// - Returns: Execution results from all agents
    /// - Throws: Execution or workflow errors
    public func execute(task: AITask) async throws -> [AIAgentOutput] {
        logger.debug("Building workflow for task execution...")
        let workflow = try await buildWorkflow(for: task)

        logger.debug("Starting workflow execution...")
        let results = try await workflow.run(prompt: "Start running the workflow")

        logger.debug("Workflow execution completed with \(results.count) outputs")
        return results
    }

    // MARK: - Private Helper Methods

    private func runAICommand<T: AIModelSchema>(_ command: String) async throws -> T {
        logger.debug("Executing AI command for type: \(T.self)")

        let result = try await managerAgent.run(prompt: command, outputSchema: T.self)

        guard let strongTypedOutput = result.allStrongTypedValues.first,
            case let .strongTypedValue(value) = strongTypedOutput,
            let typedResult = value as? T
        else {
            logger.error("Failed to extract typed result from AI response")
            throw Error.wrongResponseFormatFromAI
        }

        return typedResult
    }

    private func validatePlan(_ task: AITask) throws {
        guard let subTasks = task.subTasks, !subTasks.isEmpty else {
            throw Error.noPlan
        }

        // Validate subtask configurations
        for subtask in subTasks where subtask.temperature < 0.0 || subtask.temperature > 2.0 {
            logger.warning("Subtask '\(subtask.name)' has unusual temperature: \(subtask.temperature)")
        }
    }

    // MARK: - Public State Management

    /// Add clarifications to the goal context
    /// - Parameter clarifications: Array of clarification responses
    public func addClarifications(_ clarifications: [String]) {
        let validClarifications = clarifications.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        self.clarifications.append(contentsOf: validClarifications)
        logger.debug("Added \(validClarifications.count) clarifications")
    }

    /// Reset the goal manager state
    public func reset() {
        clarifications.removeAll()
        currentPlan = nil
        executionState = .idle
        logger.debug("Goal manager state reset")
    }

    /// Get current execution state
    public var state: ExecutionState {
        executionState
    }

    private func buildWorkflow(for task: AITask) async throws -> Workflow {
        guard let subTasks = task.subTasks, !subTasks.isEmpty else {
            throw Error.noPlan
        }

        let selectedModel = try selectOptimalModel(for: task)
        logger.debug("Selected model: \(selectedModel) for task execution")

        var agents: [AIAgent] = []
        var agentIds: [UUID] = []

        // Create agents for each subtask
        for subtask in subTasks {
            let agent = try await createAgent(for: subtask, using: selectedModel, in: task)
            agents.append(agent)
            agentIds.append(agent.id)
        }

        // Set up agent input dependencies
        try await configureAgentDependencies(agents: agents, task: task)

        // Build workflow structure
        let workflowSteps = buildWorkflowSteps(from: agents, task: task)

        return Workflow(step: workflowSteps)
    }

    private func selectOptimalModel(for task: AITask) throws -> AIAgentModel {
        // For now, select the first available model
        // TODO: Implement intelligent model selection based on task requirements
        guard let model = models.first else {
            throw Error.modelSelectionFailed
        }
        return model
    }

    private func createAgent(for subtask: AISubTask, using model: AIAgentModel, in task: AITask) async throws -> AIAgent {
        let context = AIAgentContext(
            """
            <finalGoal>\(self.goal)</finalGoal>
            <taskContext>\(task.agentSetup)</taskContext>
            <clarifications>\(clarifications.joined(separator: "\n"))</clarifications>

            You are agent '\(subtask.name)' with the specific goal: \(subtask.details)

            Work collaboratively with other agents to achieve the overall goal.
            """
        )

        let assignedTools = selectToolsForSubtask(subtask)
        let assignedMCPServers = selectMCPServersForSubtask(subtask)

        return try await AIAgent(
            title: subtask.name,
            model: model,
            tools: assignedTools,
            mcpServers: assignedMCPServers,
            context: context,
            instruction: subtask.details,
            temperature: subtask.temperature
        )
    }

    private func selectToolsForSubtask(_ subtask: AISubTask) -> [AIAgentTool] {
        guard let requiredTools = subtask.tools else { return [] }

        return tools.filter { tool in
            !Set(tool.methodMap.keys).intersection(Set(requiredTools)).isEmpty
        }
    }

    private func selectMCPServersForSubtask(_ subtask: AISubTask) -> [MCPServer] {
        // TODO: Implement intelligent MCP server selection based on subtask requirements
        mcpServers
    }

    private func configureAgentDependencies(agents: [AIAgent], task: AITask) async throws {
        // TODO: Implement sophisticated dependency management
        // For now, create a simple sequential dependency chain
        for (index, agent) in agents.enumerated() {
            var addedIndex = index - 1
            while addedIndex > 0 {
                await agent.add(input: agents[addedIndex].id)
                addedIndex -= 1
            }
        }
    }

    private func buildWorkflowSteps(from agents: [AIAgent], task: AITask) -> Workflow.Step {
        let steps = agents.map { Workflow.Step.single($0) }

        // Determine execution pattern based on task configuration
        guard task.runSubTasksInParallel == true && configuration.enableParallelExecution else {
            return .sequence(steps)
        }
        return .parrallel(steps)
    }
}

// MARK: - Extensions

extension AITask {
    var agentSetup: String {
        guard let subTasks = subTasks, !subTasks.isEmpty else {
            return "Single agent task execution"
        }

        let agentDescriptions = subTasks.enumerated()
            .map { index, agent in
                """
                <agent \(index + 1)>
                Name: \(agent.name)
                Task: \(agent.details)
                Tools: \(agent.tools?.joined(separator: ", ") ?? "none")
                Temperature: \(agent.temperature)
                </agent \(index + 1)>
                """
            }
            .joined(separator: "\n")

        return """
            Collaborative execution with \(subTasks.count) specialized agents:
            \(agentDescriptions)

            Execution mode: \(runSubTasksInParallel == true ? "Parallel" : "Sequential")
            """
    }
}

extension GoalManager {
    /// Convenience method to run with clarifications already provided
    /// - Parameter clarifications: Pre-provided clarifications
    /// - Returns: Execution results
    public func runWithClarifications(_ clarifications: [String]) async throws -> [AIAgentOutput] {
        addClarifications(clarifications)
        return try await run(skipClarification: true)
    }

    /// Get a summary of the current goal and its state
    public var summary: String {
        """
        Goal: \(goal)
        State: \(executionState)
        Clarifications: \(clarifications.count)
        Available Models: \(models.count)
        Available Tools: \(tools.count)
        Available MCP Servers: \(mcpServers.count)
        """
    }
}
