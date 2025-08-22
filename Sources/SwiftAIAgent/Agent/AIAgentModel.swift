import AIAgentMacros

public enum Modality: String, Codable, Sendable {
    case unspecified = "MODALITY_UNSPECIFIED"
    case text = "TEXT"
    case image = "IMAGE"
    case audio = "AUDIO"
}

public struct InlineData: Codable, Sendable {
    let mimeType: String
    /// The base64-encoded data.
    let data: String

    public init(mimeType: String, data: String) {
        self.mimeType = mimeType
        self.data = data
    }
}
/// AIAgentModel which abstract away the differences of LLMs
public protocol AIAgentModel: Sendable, CustomStringConvertible {
    /// Rum prompt with LLM with structured output schema
    /// - Parameters:
    ///  - prompt: the promppt to be sent to LLM
    ///  - toolSchemas: the tool schemas that can be used
    ///  - outputSchema: the output schema in json string format
    ///  - modalities: the modalities of the generated content
    ///  - inlineData: the data uploaded to work with the prompt
    /// - Returns: A wrapper of all types of output of LLM
    func run(
        prompt: String,
        outputSchema: String?,
        toolSchemas: [String]?,
        modalities: [Modality]?,
        inlineData: InlineData?
    ) async throws -> [AIAgentOutput]

    /// Rum prompt with LLM with structured output schema
    /// - Parameters:
    ///  - prompt: the promppt to be sent to LLM
    ///  - outputSchema: the json schema of the expected output in Swift Strong type
    ///  - toolSchemas: the tool schemas that can be used
    ///  - modalities: the modalities of the generated content
    ///  - inlineData: the data uploaded to work with the prompt
    /// - Returns: A wrapper of all types of output of LLM that contain strong typed value
    func run(
        prompt: String,
        outputSchema: AIModelSchema.Type,
        toolSchemas: [String]?,
        modalities: [Modality]?,
        inlineData: InlineData?
    ) async throws -> [AIAgentOutput]

    /// Description of the model capability and usage to be used in planning process
    nonisolated var description: String { get }
}
