import Foundation
import AIAgentMacros

extension GeminiSDK {
    public func textGeneration(request: GeminiRequest) async throws -> [GeminiOutput] {
        var urlRequest = URLRequest(url: URL(string: "\(baseURL)/\(model):generateContent")!)
        urlRequest.setupGeminiAPI(for: self)
        urlRequest.httpBody = try JSONEncoder().encode(request)
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let functioncalls = try data.functionCalls()
        let text = try JSONDecoder().decode(GeminiResponse.self, from: data).text
        return [.text(text), .functionCalls(functioncalls)]
    }

    public func textGeneration(prompt: String,
                               responseJsonSchema: String? = nil,
                               tools: [GeminiRequest.Tool] = []) async throws -> [GeminiOutput] {
        let request = GeminiRequest(prompt: prompt,
                                    responseJsonSchema: responseJsonSchema,
                                    tools: tools)
        return try await textGeneration(request: request)
    }

    public func textGeneration<T: AIModelOutput>(prompt: String,
                                                 responseSchema: T.Type? = nil,
                                                 tools: [GeminiRequest.Tool] = []) async throws -> [GeminiOutput] {
        let request = GeminiRequest(prompt: prompt,
                                    responseJsonSchema: responseSchema?.outputSchema,
                                    tools: tools)
        let result = try await textGeneration(request: request)
        if case let .text(jsonString) = result.firstText {
            let value = try JSONDecoder().decode(T.self, from: Data(jsonString.utf8))
            return [.strongTypedValue(value)] + result.allFunctionCallOutputs
        }
        throw Error.wrongResponse
    }
}
