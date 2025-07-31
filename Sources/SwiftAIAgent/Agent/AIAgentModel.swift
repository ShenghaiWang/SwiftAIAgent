import AIAgentMacros

/// AIAgentModel which abstract away the differences of LLMs
public protocol AIAgentModel: Sendable {

    /// Rum prompt with LLM with structured output schema
    /// - Parameters:
    ///  - prompt: the promppt to be sent to LLM
    ///  - toolSchemas: the tool schemas that can be used
    /// - Returns: A wrapper of all types of output of LLM
    func run(prompt: String, outputSchema: String?, toolSchemas: [String]?) async throws -> [AIAgentOutput]

    /// Rum prompt with LLM with structured output schema
    /// - Parameters:
    ///  - prompt: the promppt to be sent to LLM
    ///  - outputSchema: the json schema of the expected output using Swift Strong type
    ///  - toolSchemas: the tool schemas that can be used
    /// - Returns: A wrapper of all types of output of LLM
    func run<T: AIModelOutput>(prompt: String, outputSchema: T.Type?, toolSchemas: [String]?) async throws -> [AIAgentOutput]
}
