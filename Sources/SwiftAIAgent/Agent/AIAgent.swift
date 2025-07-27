import Foundation
import AIAgentMacros

/// AIAgent type that wrap llm, context, instruction, tools, mcp servers that can work independently for a single task.
public final actor AIAgent: Sendable {
    public let id = UUID()
    let title: String
    let context: AIAgentContext?
    let model: AIAgentModel
    let tools: [any AIAgentTool]
    let mcpServers: [any MCPServer]
    let instruction: String?
    private(set) var inputs: [UUID] = []

    /// Initialise an AI Agent
    /// - Parameters:
    ///  - title: The name of the agent
    ///  - model: The LLM to use for the task that assigned to this agent
    ///  - tools: The tools can be used by this agent
    ///  - mcpServers: The MCP server can be used by this agent
    ///  - context: The context for the task that assigned to this agent
    ///  - instruction: The instruction for the task that assigned to this agent
    public init(title: String,
                model: AIAgentModel,
                tools: [any AIAgentTool] = [],
                mcpServers: [any MCPServer] = [],
                context: AIAgentContext? = nil,
                instruction: String? = nil) {
        self.title = title
        self.model = model
        self.context = context
        self.tools = tools
        self.mcpServers = mcpServers
        self.instruction = instruction
    }

    func run(prompt: String, outputSchema: String? = nil) async throws -> AIAgentOutput {
        let combinedPrompt = await combined(prompt: prompt)
        logger.debug("\n===Agent ID\(id)===\n===Input===\n\(combinedPrompt)\n")
        let result = try await model.run(prompt: combinedPrompt,
                                         outputSchema: outputSchema)
        await Runtime.shared.set(output: result, for: id, title: title)
        logger.debug("\n===Agent ID\(id)===\n===Output===\n\(result.output)\n")
        return result
    }

    /// Run agent for the task with the prompt
    /// - Parameters:
    ///  - prompt: Along with context, instruction, prompmt defines the task for this agent.
    ///  - outputSchema: The output type, which is used guide LLM for structured output
    public func run<T: AIModelOutput>(prompt: String, outputSchema: T.Type) async throws -> AIAgentOutput {
        let combinedPrompt = await combined(prompt: prompt)
        logger.debug("\n===Agent ID\(id)===\n===Input===\n\(combinedPrompt)\n")
        let result = try await model.run(prompt: combinedPrompt,
                                         outputSchema: outputSchema)
        await Runtime.shared.set(output: result, for: id, title: title)
        logger.debug("\n===Agent ID\(id)===\n===Output===\n\(result.output)\n")
        return result
    }

    private func combined(prompt: String) async -> String {
        var contents: [String] = []
        if let context {
            contents.append("<context>\(context.contenxt)</context>")
        }
        if let instruction {
            contents.append("<instruction>\(instruction)</instruction>")
        }
        for uuid in inputs {
            if let cache = await Runtime.shared.output(of: uuid) {
                contents.append("<\(cache.title)>\(cache.output.output)</\(cache.title)>")
            }
        }
        contents.append(prompt)
        return contents.joined()
    }

    /// In case of agent workflow, use this method to inject ouput from another agent
    /// - Parameters:
    ///  - input: the agent ID to be added. The added agent's output will be part of input of this agent.
    public func add(input agentId: UUID) {
        inputs.append(agentId)
    }
}
