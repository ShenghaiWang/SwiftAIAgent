import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class GeminiSDK: Sendable {
    let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models")!
    let apiKey: String
    let model: String

    public init(model: String, apiKey: String) {
        self.model = model
        self.apiKey = apiKey
    }
}

extension URLRequest {
    mutating func setupGeminiAPI(for sdk: GeminiSDK) {
        httpMethod = "POST"
        addValue("application/json", forHTTPHeaderField: "Content-Type")
        addValue("application/json", forHTTPHeaderField: "Accept")
        addValue(sdk.apiKey, forHTTPHeaderField: "x-goog-api-key")
    }
}
