import AIAgentMacros

public protocol AIAgentModel: Sendable {
    func run(prompt: String, outputSchema: String?) async throws -> AIAgentOutput

    func run<T: AIModelOutput>(prompt: String, outputSchema: T.Type) async throws -> AIAgentOutput
}
