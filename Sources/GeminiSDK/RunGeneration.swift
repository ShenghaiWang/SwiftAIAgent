import Foundation
import AIAgentMacros
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension GeminiSDK {
    /// Rum prompt with Gmini
    /// - Parameters:
    ///  - request: the request to be sent to Gemini
    /// - Returns: A wrapper of all types of output of Gemini
    public func run(request: GeminiRequest) async throws -> [GeminiOutput] {
        var output: [GeminiOutput] = []
        var urlRequest = URLRequest(url: URL(string: "\(baseURL)/\(model):generateContent")!)
        urlRequest.setupGeminiAPI(for: self)
        urlRequest.httpBody = try JSONEncoder().encode(request)
        let (data, httpURLResponse) = try await urlSession.data(for: urlRequest)
        guard let statusCode = (httpURLResponse as? HTTPURLResponse)?.statusCode,
                200..<300 ~= statusCode else {
            throw Error.invalidResponse(responseStatusCode: (httpURLResponse as? HTTPURLResponse)?.statusCode)
        }
        let functioncalls = try data.functionCalls()
        output.append(.functionCalls(functioncalls))

        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)

        if let text = response.text, !text.isEmpty {
            output.append(.text(text))
        }
        if let base64String = response.inlineData?.data, let data = Data(base64Encoded: base64String) {
            if request.generationConfig?.responseModalities?.contains(.audio) ?? false {
                output.append(.audio(data))
            } else {
                output.append(.image(data))
            }
        }
        return output
    }
}
