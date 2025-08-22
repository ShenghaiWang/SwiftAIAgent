import AIAgentMacros
import Foundation
import MCP

/// AIAgent type that wrap llm, context, instruction, tools, mcp servers that can work independently for a single task.
public final actor AIAgent: Sendable {
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
    nonisolated let mcpServers: [MCPServer]
    nonisolated let instruction: String?
    private(set) var inputs: [UUID] = []
    private let mcpClients: [UUID: Client]
    private(set) var mcpTools: [UUID: [MCP.Tool]] = [:]
    /// Initialise an AI Agent
    /// - Parameters:
    ///  - title: The name of the agent
    ///  - model: The LLM to use for the task that assigned to this agent
    ///  - tools: The tools can be used by this agent
    ///  - mcpServers: The MCP server can be used by this agent
    ///  - context: The context for the task that assigned to this agent
    ///  - instruction: The instruction for the task that assigned to this agent
    public init(
        title: String,
        model: AIAgentModel,
        tools: [any AIAgentTool] = [],
        mcpServers: [MCPServer] = [],
        context: AIAgentContext? = nil,
        instruction: String? = nil
    ) async throws {
        self.title = title
        self.model = model
        self.context = context
        self.tools = tools
        self.mcpServers = mcpServers
        self.instruction = instruction
        inputs.append(id)
        mcpClients = try await mcpServers.async.map { try await $0.connect() }.collect()
            .reduce(
                into: [UUID: Client](),
                { result, client in
                    result[UUID()] = client
                })
        for (key, client) in mcpClients {
            var allTools: [MCP.Tool] = []
            var (tools, nextCursor) = try await client.listTools()
            allTools.append(contentsOf: tools)
            while nextCursor != nil {
                let (tools, cursor) = try await client.listTools(cursor: nextCursor)
                nextCursor = cursor
                allTools.append(contentsOf: tools)
            }
            mcpTools[key] = allTools
        }
    }

    var toolDefinitions: [String] {
        tools.toolDefinitions + mcpTools.values.flatMap { $0.map(\.toolDefinition) }
    }

    /// Rum prompt with LLM with structured output schema
    /// - Parameters:
    ///  - prompt: the promppt to be sent to LLM
    ///  - outputSchema: the output schema in json string format
    ///  - modalities: the modalities of the generated content
    ///  - inlineData: the inlineData to be working with prompt
    /// - Returns: A wrapper of all types of output of LLM
    public func run(
        prompt: String,
        outputSchema: String? = nil,
        modalities: [Modality] = [.text],
        inlineData: InlineData? = nil
    ) async throws -> [AIAgentOutput] {
        try await runInternal(
            prompt: prompt, outputSchema: outputSchema, modalities: modalities,
            inlineData: inlineData)
    }

    /// Run agent for the task with the prompt
    /// - Parameters:
    ///  - prompt: Along with context, instruction, prompmt defines the task for this agent.
    ///  - outputSchema: The output type, which is used guide LLM for structured output
    ///  - modalities: the modalities of the generated content
    ///  - inlineData: the inlineData to be working with prompt
    /// - Returns: A wrapper of all types of output of LLM that contain strong typed value
    public func run(
        prompt: String,
        outputSchema: AIModelSchema.Type,
        modalities: [Modality] = [.text],
        inlineData: InlineData? = nil
    ) async throws -> [AIAgentOutput] {
        try await runInternal(
            prompt: prompt, outputSchema: outputSchema, modalities: modalities,
            inlineData: inlineData)
    }

    private func runInternal<T>(
        prompt: String,
        outputSchema: T,
        modalities: [Modality] = [.text],
        inlineData: InlineData? = nil
    ) async throws -> [AIAgentOutput] {
        let combinedPrompt = await combined(prompt: prompt)
        logger.debug("\n\(description)\n===Input===\n\(combinedPrompt)\n")
        var result: [AIAgentOutput] =
            if let schema = outputSchema as? AIModelSchema.Type {
                try await model.run(
                    prompt: combinedPrompt,
                    outputSchema: schema,
                    toolSchemas: toolDefinitions,
                    modalities: modalities,
                    inlineData: inlineData)
            } else {
                try await model.run(
                    prompt: combinedPrompt,
                    outputSchema: outputSchema as? String,
                    toolSchemas: toolDefinitions,
                    modalities: modalities,
                    inlineData: inlineData)
            }
        await Runtime.shared.set(output: result, for: id, title: title)
        let allFunctionCalls = result.allFunctionCalls
        if !allFunctionCalls.isEmpty {
            logger.debug(
                "\n\(description)\n===Output before calling tools===\n\(result.allTexts)\n")
            logger.debug(
                "\n\(description)\n===Calling tools===\n\(allFunctionCalls.joined(separator: ";"))\n"
            )
            result = await callTools(with: allFunctionCalls)
            logger.debug("\n\(description)\n===Result after calling tools===\n\(result.allTexts)\n")
            logger.debug(
                "\n\(description)\n===Calling MCP Server tools===\n\(allFunctionCalls.joined(separator: ";"))\n"
            )
            result += await callMCPServers(with: allFunctionCalls)
            logger.debug(
                "\n\(description)\n===Result after calling MCP Server  tools===\n\(result.allTexts)\n"
            )
            await Runtime.shared.set(output: result, for: id, title: title)
            let combinedPrompt = await combined(prompt: "\(prompt) \(stopTooCallInstruction)")
            logger.debug(
                "\n\(description)\n===Re-run agent after calling tools===\n\(result.allTexts)\n")
            try await Task.sleep(for: .seconds(1))
            result += try await runInternal(
                prompt: combinedPrompt,
                outputSchema: outputSchema,
                modalities: modalities,
                inlineData: inlineData)
        }
        await Runtime.shared.set(output: result, for: id, title: title)
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
                contents.append(
                    "<\(resultTag)><\(cache.title)>\(cache.output.allTexts.joined(separator: "\n"))</\(cache.title)></\(resultTag)>"
                )
            }
        }
        contents.append("<result_of_the_previous_step>\(prompt)</result_of_the_previous_step>")
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
                    let callResult = try await tool.call(
                        toolCallingValue.name, args: toolCallingValue.args)
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

    private func callMCPServers(with allFunctionCalls: [String]) async -> [AIAgentOutput] {
        let toolCallingValues = allFunctionCalls.compactMap(ToolCallingValue.init(value:))
        var results: [AIAgentOutput] = []
        for toolCallingValue in toolCallingValues {
            guard
                let clientKey = mcpTools.filter({
                    $0.value.compactMap(\.name).contains(toolCallingValue.name)
                }).first?.key,
                let mcpClient = mcpClients[clientKey]
            else {
                continue
            }
            do {
                let callResult = try await mcpClient.callTool(
                    name: toolCallingValue.name,
                    arguments: toolCallingValue.args
                        .mapValues {
                            (try? JSONDecoder().decode(Value.self, from: $0)) ?? .string("")
                        })
                results.append(.text("<Result_of_calling_function_\(toolCallingValue.name)>"))
                results.append(contentsOf: callResult.content.map(\.aiAgentOutput))
                results.append(.text("</Result_of_calling_function_\(toolCallingValue.name)>"))
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
