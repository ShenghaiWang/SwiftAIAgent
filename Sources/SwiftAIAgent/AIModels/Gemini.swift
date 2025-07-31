import Foundation
import GeminiSDK
import AIAgentMacros

extension GeminiSDK: AIAgentModel {    
    public func run<T: AIModelOutput>(prompt: String,
                                      outputSchema: T.Type? = nil,
                                      toolSchemas: [String]? = nil) async throws -> [AIAgentOutput] {
        let functionDeclarations = toolSchemas?.compactMap(\.functionDeclaration) ?? []
        let result = try await textGeneration(prompt: prompt,
                                              responseSchema: outputSchema,
                                              tools: [.init(functionDeclarations: functionDeclarations)])
        return result.aiAgentOutput
    }
    
    public func run(prompt: String,
                    outputSchema: String? = nil,
                    toolSchemas: [String]? = nil) async throws -> [AIAgentOutput] {
        let functionDeclarations = toolSchemas?.compactMap(\.functionDeclaration) ?? []
        let result = try await textGeneration(prompt: prompt,
                                              responseJsonSchema: outputSchema,
                                              tools: [.init(functionDeclarations: functionDeclarations)])
        return result.aiAgentOutput
    }
}

extension String {
    var functionDeclaration: GeminiRequest.Tool.FunctionDeclaration? {
        /// parsing name, description, parametersJsonSchema from the string to initiate FunctionDeclaration
        guard let data = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        guard let name = json["name"] as? String,
              let description = json["description"] as? String else {
            return nil
        }
        // parametersJsonSchema can be a dictionary or a string
        var parametersJsonSchemaString: String?
        if let schemaDict = json["parametersJsonSchema"] as? [String: Any],
           let schemaData = try? JSONSerialization.data(withJSONObject: schemaDict, options: .sortedKeys),
           let schemaString = String(data: schemaData, encoding: .utf8) {
            parametersJsonSchemaString = schemaString
        } else if let schemaString = json["parametersJsonSchema"] as? String {
            parametersJsonSchemaString = schemaString
        }
        guard let parametersJsonSchema = parametersJsonSchemaString else {
            return nil
        }
        return GeminiRequest.Tool.FunctionDeclaration(
            name: name,
            description: description,
            parametersJsonSchema: parametersJsonSchema
        )
    }
}

extension GeminiOutput {
    var aiAgentOutput: AIAgentOutput? {
        switch self {
        case let .functionCalls(calls): .functionCalls(calls)
        case let .strongTypedValue(value): .strongTypedValue(value)
        case let .text(text): .text(text)
        }
    }
}

extension Array where Element == GeminiOutput {
    var aiAgentOutput: [AIAgentOutput] {
        compactMap(\.aiAgentOutput)
    }
}
