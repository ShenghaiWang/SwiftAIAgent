import Foundation
import AIAgentMacros

/// AIAgent type that wrap llm, context, instruction, tools, mcp servers that can work independently for a single task.
public final actor AIAgent: Sendable {
    private let maxRunCount: Int
    private let resultTag = "latest result of agent run of "
    private let stopTooCallInstruction =
        """
        Please check the result of the function tool calls. 
        If we don't need to call these function tools anymore, DO NOT RETURN FUNCTIONS TO CALL.
        """
    public nonisolated let id = UUID()
    nonisolated let title: String
    nonisolated let context: AIAgentContext?
    nonisolated let model: AIAgentModel
    nonisolated let tools: [any AIAgentTool]
    nonisolated let mcpServers: [any MCPServer]
    nonisolated let instruction: String?
    private(set) var inputs: [UUID] = []
    private var runCount: Int = 0

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
                instruction: String? = nil,
                maxRunCount: Int = 3) {
        self.title = title
        self.model = model
        self.context = context
        self.tools = tools
        self.mcpServers = mcpServers
        self.instruction = instruction
        self.maxRunCount = maxRunCount
        inputs.append(id)
    }

    var toolDefinitions: [String] {
        tools.toolDefinitions
    }

    /// Rum prompt with LLM with structured output schema
    /// - Parameters:
    ///  - prompt: the promppt to be sent to LLM
    ///  - outputSchema: the output schema in json string format
    ///  - modalities: the modalities of the generated content
    ///  - inlineData: the inlineData to be working with prompt
    /// - Returns: A wrapper of all types of output of LLM
    public func run(prompt: String,
                    outputSchema: String? = nil,
                    modalities: [Modality] = [.text],
                    inlineData: InlineData? = nil) async throws -> [AIAgentOutput] {
        try await runInternal(prompt: prompt, outputSchema: outputSchema, modalities: modalities, inlineData: inlineData)
    }

    /// Run agent for the task with the prompt
    /// - Parameters:
    ///  - prompt: Along with context, instruction, prompmt defines the task for this agent.
    ///  - outputSchema: The output type, which is used guide LLM for structured output
    ///  - modalities: the modalities of the generated content
    ///  - inlineData: the inlineData to be working with prompt
    /// - Returns: A wrapper of all types of output of LLM that contain strong typed value
    public func run(prompt: String,
                    outputSchema: AIModelSchema.Type,
                    modalities: [Modality] = [.text],
                    inlineData: InlineData? = nil) async throws -> [AIAgentOutput] {
        try await runInternal(prompt: prompt, outputSchema: outputSchema, modalities: modalities, inlineData: inlineData)
    }

    private func runInternal<T>(prompt: String,
                                outputSchema: T,
                                modalities: [Modality] = [.text],
                                inlineData: InlineData? = nil) async throws -> [AIAgentOutput] {
        runCount += 1
        let combinedPrompt = await combined(prompt: prompt)
        logger.debug("\n\(description)\n===Input===\n\(combinedPrompt)\n")
        var result: [AIAgentOutput] = if let schema = outputSchema as? AIModelSchema.Type {
            try await model.run(prompt: combinedPrompt,
                                outputSchema: schema,
                                toolSchemas: toolDefinitions,
                                modalities: modalities,
                                inlineData: inlineData)
        } else {
            try await model.run(prompt: combinedPrompt,
                                outputSchema: outputSchema as? String,
                                toolSchemas: toolDefinitions,
                                modalities: modalities,
                                inlineData: inlineData)
        }
        await Runtime.shared.set(output: result, for: id, title: title)
        let allFunctionCalls = result.allFunctionCalls
        if !allFunctionCalls.isEmpty && runCount <= maxRunCount {
            logger.debug("\n\(description)\n===Output before calling tools===\n\(result.allTexts)\n")
            logger.debug("\n\(description)\n===Calling tools===\n\(allFunctionCalls.joined(separator: ";"))\n")
            result += await callTools(with: allFunctionCalls)
            await Runtime.shared.set(output: result, for: id, title: title)
            logger.debug("\n\(description)\n===Rerun agent with result from tools===\n\(result.allTexts)\n")
            let combinedPrompt = await combined(prompt: "\(prompt) \(stopTooCallInstruction)")
            result += try await runInternal(prompt: combinedPrompt,
                                            outputSchema: outputSchema,
                                            modalities: modalities,
                                            inlineData: inlineData)
        }
        logger.debug("\n\(description)\n===Output===\n\(result.allTexts)\n")
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
                contents.append("<\(resultTag) \(cache.title)>\(cache.output.allTexts)</\(resultTag) \(cache.title))>")
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

    private func callTools(with allFunctionCalls: [String]) async -> [AIAgentOutput] {
        let toolCallingValues = allFunctionCalls.compactMap(ToolCallingValue.init(value:))
        var results: [AIAgentOutput] = []
        for toolCallingValue in toolCallingValues {
            for tool in tools {
                do {
                    let callResult = try await tool.call(toolCallingValue.name, args: toolCallingValue.args)
                    results.append(
                        .text(
                        """
                        <Result_of_calling_function_\(toolCallingValue.name)>
                        <args>\(toolCallingValue.argsString)</args>
                        \(callResult ?? "")
                        </Result_of_calling_function_\(toolCallingValue.name)>
                        """
                        ))
                } catch {
                    results.append(
                        .text(
                        """
                        <Result_of_calling_function_\(toolCallingValue.name)>
                        <args>\(toolCallingValue.argsString)</args>
                        \(error.localizedDescription)
                        </Result_of_calling_function_\(toolCallingValue.name)>
                        """
                        ))
                }
            }
        }
        return results
    }
}

extension AIAgent: CustomStringConvertible {
    public nonisolated var description: String {
        """
        ===AIAgent===
        ID: \(id) Title: \(title)
        Model: \(model)
        Context: \(context?.contenxt ?? "")
        Instruction: \(instruction ?? "")
        Tools: \(tools)
        MCP Servers: \(mcpServers)
        """
    }
}
