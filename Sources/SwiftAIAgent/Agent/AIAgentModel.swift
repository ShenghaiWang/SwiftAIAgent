import AIAgentMacros

/// AIAgentModel which abstract away the differences of LLMs
public protocol AIAgentModel: Sendable {
    /// Rum prompt with LLM with structured output scheme
    /// Parameters:
    /// - prompt: the promppt to be sent to LLM
    /// - outputSchema: the json scheme of the expected output
    /// - toolSchemas: the tool definitions, using String type to make it easy to be mapped into different LLMs
    /// Returns: A wrapper of all types of output of LLM
    func run(prompt: String, outputSchema: String?, toolSchemas: [String]?) async throws -> AIAgentOutput

    /// Rum prompt with LLM with structured output scheme
    /// Parameters:
    /// - prompt: the promppt to be sent to LLM
    /// - outputSchema: the json scheme of the expected output using Swift Strong type
    /// - toolSchemas: the tool definitions, using String type to make it easy to be mapped into different LLMs
    /// Returns: A wrapper of all types of output of LLM
    func run<T: AIModelOutput>(prompt: String, outputSchema: T.Type?, toolSchemas: [String]?) async throws -> AIAgentOutput
}
