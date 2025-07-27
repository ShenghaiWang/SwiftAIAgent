import AIAgentMacros

/// AIAgentModel which abstract away the differences of LLMs
public protocol AIAgentModel: Sendable {

    /// Rum prompt with LLM with structured output scheme
    /// Parameters:
    /// - prompt: the promppt to be sent to LLM
    /// - outputSchema: the json scheme of the expected output
    /// Returns: A wrapper of all types of output of LLM
    func run(prompt: String, outputSchema: String?) async throws -> AIAgentOutput

    /// Rum prompt with LLM with structured output scheme
    /// Parameters:
    /// - prompt: the promppt to be sent to LLM
    /// - outputSchema: the json scheme of the expected output using Swift Strong type
    /// Returns: A wrapper of all types of output of LLM
    func run<T: AIModelOutput>(prompt: String, outputSchema: T.Type) async throws -> AIAgentOutput
}
