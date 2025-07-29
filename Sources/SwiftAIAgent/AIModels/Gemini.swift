import Foundation
import GeminiSDK
import AIAgentMacros

extension GeminiSDK: AIAgentModel {
    public func run<T: AIModelOutput>(prompt: String,
                                      outputSchema: T.Type? = nil,
                                      toolSchemas: [String]? = nil) async throws -> AIAgentOutput {
        let result = try await textGeneration(prompt: prompt,
                                              responseSchema: outputSchema,
                                              tools: [

                                              ]) // TODO: map schema to gemini tool definition
        return AIAgentOutput(result: result)
    }
    
    public func run(prompt: String,
                    outputSchema: String? = nil,
                    toolSchemas: [String]? = nil) async throws -> AIAgentOutput {
        let result = try await textGeneration(prompt: prompt,
                                              responseJsonSchema: outputSchema,
                                              tools: []) // TODO: map schema to gemini tool definition
        return AIAgentOutput(result: result)
    }
}

private extension String {
    var functionDeclaration: GeminiRequest.Tool.FunctionDeclaration? {
        nil
    }
}
