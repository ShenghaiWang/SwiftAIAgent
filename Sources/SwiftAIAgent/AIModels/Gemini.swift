import Foundation
import GeminiSDK
import AIAgentMacros

extension GeminiSDK: AIAgentModel {
    public func run<T: AIModelOutput>(prompt: String, outputSchema: T.Type) async throws -> AIAgentOutput {
        let result = try await textGeneration(prompt: prompt, responseSchema: outputSchema)
        return AIAgentOutput(result: result)
    }
    
    public func run(prompt: String, outputSchema: String? = nil) async throws -> AIAgentOutput {
        let result = try await textGeneration(prompt: prompt, responseJsonSchema: outputSchema)
        return AIAgentOutput(result: result)
    }
}
