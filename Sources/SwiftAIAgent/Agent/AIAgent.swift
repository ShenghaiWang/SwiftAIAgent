import AIAgentMacros
import Foundation
import MCP

/// AIAgent type that wrap llm, context, instruction, tools, mcp servers that can work independently for a single task.
public final actor AIAgent: Sendable {
    private let resultTag = "latest result of agent run of "
    private let stopToolCallInstruction =
        """
        All the tool calls have been succeeded. 
        Please check the result of the function tool calls. 
        If do not need to call these function tools anymore, DO NOT RETURN FUNCTIONS TO CALL.
        """
    public nonisolated let id = UUID()
    nonisolated let title: String
    nonisolated let context: AIAgentContext?
    nonisolated let model: AIAgentModel
    nonisolated let tools: [any AIAgentTool]
    nonisolated let mcpServers: [MCPServer]
    nonisolated let instruction: String?
    nonisolated let temperature: Float?
    nonisolated let configuration: AIAgentConfiguration
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
    ///  - temperature: The creativity level of the model (0.0-1.0)
    ///  - configuration: Configuration for execution behavior including max iterations and delays
    public init(
        title: String,
        model: AIAgentModel,
        tools: [any AIAgentTool] = [],
        mcpServers: [MCPServer] = [],
        context: AIAgentContext? = nil,
        instruction: String? = nil,
        temperature: Float? = 0.7,
        configuration: AIAgentConfiguration = .default
    ) async throws {
        self.title = title
        self.model = model
        self.context = context
        self.tools = tools + [AIAgentOutputIO()]
        self.mcpServers = mcpServers
        self.instruction = instruction
        self.temperature = temperature
        self.configuration = configuration
        inputs.append(id)
        mcpClients = try await mcpServers.async.map { try await $0.connect() }.collect()
            .reduce(
                into: [UUID: Client](),
                { result, client in
                    result[UUID()] = client
                }
            )
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
        let result = try await runInternal(
            prompt: prompt,
            outputSchema: outputSchema,
            modalities: modalities,
            inlineData: inlineData
        )
        try await Runtime.shared.set(output: result, for: id, title: title, useTempFiles: true)
        return result
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
        let result = try await runInternal(
            prompt: prompt,
            outputSchema: outputSchema,
            modalities: modalities,
            inlineData: inlineData
        )
        try await Runtime.shared.set(output: result, for: id, title: title, useTempFiles: true)
        return result
    }

    private func runInternal<T>(
        prompt: String,
        outputSchema: T,
        modalities: [Modality] = [.text],
        inlineData: InlineData? = nil
    ) async throws -> [AIAgentOutput] {
        let initialPrompt = await combined(prompt: prompt)
        logger.debug("\n\(description)\n===Input===\n\(initialPrompt)\n")

        var currentPrompt = initialPrompt
        var iteration = 0

        while iteration < configuration.maxToolIterations {
            iteration += 1
            logger.debug("\n\(description)\n===Iteration \(iteration)===\n")

            // Execute LLM call
            let result: [AIAgentOutput] = try await executeLLMCall(
                prompt: currentPrompt,
                outputSchema: outputSchema,
                modalities: modalities,
                inlineData: inlineData
            )

            let allFunctionCalls = result.allFunctionCalls

            if allFunctionCalls.isEmpty {
                // No more tools to call, we're done
                logger.debug("\n\(description)\n===Final Output===\n\(result.allTexts)\n")
                return result
            }

            // Execute tools and prepare for next iteration
            logger.debug("\n\(description)\n===Iteration \(iteration) - Calling tools===\n\(allFunctionCalls.joined(separator: ";"))\n")
            let toolResults = await executeAllTools(allFunctionCalls)

            // Prepare prompt for next iteration
            currentPrompt = await combined(
                prompt: """
                    \(prompt)
                    <previous_llm_response>
                    \(result.allTexts.joined(separator: "\n"))
                    </previous_llm_response>
                    <tool_execution_results>
                    \(toolResults.allTexts.joined(separator: "\n"))
                    </tool_execution_results>
                    \(stopToolCallInstruction)
                    """
            )

            // Delay to avoid rate limiting and allow for processing
            try await Task.sleep(for: configuration.toolExecutionDelay)
        }

        // If we reach here, we've exceeded max iterations
        // Make one final call without tools to get a response
        logger.debug("\n\(description)\n===Max iterations reached, making final call===\n")
        let finalResult = try await executeLLMCall(
            prompt: currentPrompt,
            outputSchema: outputSchema,
            modalities: modalities,
            inlineData: inlineData,
            allowTools: false
        )

        throw AIAgentError.maxIterationsReached(lastResult: finalResult)
    }

    private func combined(prompt: String) async -> String {
        var contents: [String] = []
        if let context {
            contents.append("<context>\(context.context)</context>")
        }
        if let instruction {
            contents.append("<instruction>\(instruction)</instruction>")
        }
        for uuid in inputs {
            if let cache = await Runtime.shared.output(of: uuid) {
                contents.append(
                    """
                    <\(resultTag)>
                        <\(cache.title)>
                            \(cache.output.allTexts.joined(separator: "\n"))
                            \(cache.cachedFiles)
                        </\(cache.title)>
                    </\(resultTag)>
                    """
                )
            }
        }
        contents.append(prompt)
        contents.append("<instruction>Please execute the task based on the context, instruction and results from other agents.</instruction>")
        return contents.joined()
    }

    /// In case of agent workflow, use this method to inject ouput from another agent
    /// - Parameters:
    ///  - input: the agent ID to be added. The added agent's output will be part of input of this agent.
    public func add(input agentId: UUID) {
        inputs.append(agentId)
    }

    // MARK: - Helper Methods

    /// Execute a single LLM call with the given parameters
    private func executeLLMCall<T>(
        prompt: String,
        outputSchema: T,
        modalities: [Modality],
        inlineData: InlineData?,
        allowTools: Bool = true
    ) async throws -> [AIAgentOutput] {
        guard let schema = outputSchema as? AIModelSchema.Type else {
            return try await model.run(
                prompt: prompt,
                outputSchema: outputSchema as? String,
                toolSchemas: allowTools ? toolDefinitions : [],
                modalities: modalities,
                inlineData: inlineData,
                temperature: temperature
            )
        }
        return try await model.run(
            prompt: prompt,
            outputSchema: schema,
            toolSchemas: [],  // Cannot have toolSchemas if requesting structured output
            modalities: modalities,
            inlineData: inlineData,
            temperature: temperature
        )
    }

    /// Execute all tools (both native and MCP) for the given function calls
    private func executeAllTools(_ functionCalls: [String]) async -> [AIAgentOutput] {
        logger.debug("\n\(description)\n===Executing tools===\n")

        var allResults: [AIAgentOutput] = []

        // Execute native tools
        let nativeResults = await callTools(with: functionCalls)
        allResults.append(contentsOf: nativeResults)
        logger.debug("\n\(description)\n===Native tools results===\n\(nativeResults.allTexts.joined(separator: "\n"))\n")

        // Execute MCP server tools
        let mcpResults = await callMCPServers(with: functionCalls)
        allResults.append(contentsOf: mcpResults)
        logger.debug("\n\(description)\n===MCP tools results===\n\(mcpResults.allTexts.joined(separator: "\n"))\n")

        return allResults
    }

    private func callTools(with allFunctionCalls: [String]) async -> [AIAgentOutput] {
        let toolCallingValues = allFunctionCalls.compactMap(ToolCallingValue.init(value:))
        var results: [AIAgentOutput] = []
        for toolCallingValue in toolCallingValues {
            for tool in tools where tool.methodMap.keys.contains(toolCallingValue.name) {
                do {
                    let callResult = try await tool.call(
                        toolCallingValue.name,
                        args: toolCallingValue.args
                    )
                    results.append(
                        .text(
                            """
                            <Result_of_calling_function_\(toolCallingValue.name)>
                            <args>\(toolCallingValue.argsString)</args>
                            <success_result>\(callResult ?? "")</success_result>
                            </Result_of_calling_function_\(toolCallingValue.name)>
                            """
                        )
                    )
                } catch {
                    results.append(
                        .text(
                            """
                            <Result_of_calling_function_\(toolCallingValue.name)>
                            <args>\(toolCallingValue.argsString)</args>
                            <error_result>\(error.localizedDescription)</error_result>
                            </Result_of_calling_function_\(toolCallingValue.name)>
                            """
                        )
                    )
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
                let clientKey =
                    mcpTools.filter({
                        $0.value.compactMap(\.name).contains(toolCallingValue.name)
                    })
                    .first?
                    .key,
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
                        }
                )
                results.append(
                    .text(
                        """
                        <Result_of_calling_function_\(toolCallingValue.name)>
                        <success_result>\(callResult.content.map(\.aiAgentOutput))</success_result>
                        </Result_of_calling_function_\(toolCallingValue.name)>
                        """
                    )
                )
            } catch {
                results.append(
                    .text(
                        """
                        <Result_of_calling_function_\(toolCallingValue.name)>
                        <args>\(toolCallingValue.argsString)</args>
                        <error_result>\(error.localizedDescription)</error_result>
                        </Result_of_calling_function_\(toolCallingValue.name)>
                        """
                    )
                )
            }
        }
        return results
    }
}

extension AIAgent: CustomStringConvertible {
    public nonisolated var description: String {
        """
        ===AIAgent===
        Title: \(title)
        ID: \(id)
        Model: \(model)
        Context: \(context?.context ?? "")
        Instruction: \(instruction ?? "")
        Tools: \(tools)
        MCP Servers: \(mcpServers)
        Configuration: Max iterations: \(configuration.maxToolIterations), Delay: \(configuration.toolExecutionDelay)
        """
    }
}
