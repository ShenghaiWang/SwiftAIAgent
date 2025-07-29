import Foundation
import AIAgentMacros

extension GeminiSDK {
    public func textGeneration(request: GeminiRequest) async throws -> String {
        var urlRequest = URLRequest(url: URL(string: "\(baseURL)/\(model):generateContent")!)
        urlRequest.setupGeminiAPI(for: self)
        urlRequest.httpBody = try JSONEncoder().encode(request)
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        if request.requestingFunctionCalls {
            return try data.functionCalls().joined(separator: "\n")
        } else {
            let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
            return result.text
        }
    }

    public func textGeneration(prompt: String,
                               responseJsonSchema: String? = nil,
                               tools: [GeminiRequest.Tool] = []) async throws -> String {
        let request = GeminiRequest(prompt: prompt,
                                    responseJsonSchema: responseJsonSchema,
                                    tools: tools)
        return try await textGeneration(request: request)
    }

    public func textGeneration<T: AIModelOutput>(prompt: String,
                                                 responseSchema: T.Type? = nil,
                                                 tools: [GeminiRequest.Tool] = []) async throws -> T {
        let request = GeminiRequest(prompt: prompt,
                                    responseJsonSchema: responseSchema?.outputSchema,
                                    tools: tools)
        let jsonString = try await textGeneration(request: request)
        return try JSONDecoder().decode(T.self, from: Data(jsonString.utf8))
    }
}
