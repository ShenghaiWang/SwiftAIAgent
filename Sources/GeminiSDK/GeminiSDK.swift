import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public final class GeminiSDK: Sendable {
    let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models")!
    let apiKey: String
    let model: String
    let urlSession: URLSession

    public init(
        model: String,
        apiKey: String,
        urlSessionConfiguration: URLSessionConfiguration? = nil
    ) {
        self.model = model
        self.apiKey = apiKey
        if let configuration = urlSessionConfiguration {
            urlSession = URLSession(configuration: configuration)
        } else {
            urlSession = .shared
            urlSession.configuration.timeoutIntervalForRequest = 600
        }
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
