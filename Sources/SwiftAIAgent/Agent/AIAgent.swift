import Foundation
import AIAgentMacros

public final actor AIAgent: Sendable {
    public let id = UUID()
    let title: String
    let context: AIAgentContext?
    let model: AIAgentModel
    let tools: [any AIAgentTool]
    let mcpServers: [any MCPServer]
    let instruction: String?
    private(set) var inputs: [UUID] = []

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

    public func run(prompt: String, outputSchema: String? = nil) async throws -> AIAgentOutput {
        let combinedPrompt = await combined(prompt: prompt)
        logger.debug("\n===Agent ID\(id)===\n===Input===\n\(combinedPrompt)\n")
        let result = try await model.run(prompt: combinedPrompt,
                                         outputSchema: outputSchema)
        await Runtime.shared.set(output: result, for: id, title: title)
        logger.debug("\n===Agent ID\(id)===\n===Output===\n\(result.output)\n")
        return result
    }

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

    public func add(input: UUID) {
        inputs.append(input)
    }
}
