import AIAgentMacros
import Foundation
import SwiftSoup

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// A tool that fetches the content of the url
@AITool
public struct Fetch {
    public enum Error: Swift.Error {
        case invalidURL
        case invalidResponse(responseStatusCode: Int)
    }
    public init() {}

    /// Fetch the text content of the url
    /// - Parameter url: the url to be fetched
    /// - Returns: the text content of the url
    public func fetch(url: String) async throws -> String? {
        guard let url = URL(string: url) else {
            throw Error.invalidURL
        }
        let (data, httpURLResponse) = try await URLSession.shared.data(from: url)
        guard let statusCode = (httpURLResponse as? HTTPURLResponse)?.statusCode,
            200..<300 ~= statusCode
        else {
            throw Error.invalidResponse(
                responseStatusCode: (httpURLResponse as? HTTPURLResponse)?.statusCode ?? 0
            )
        }
        guard let html = String(data: data, encoding: .utf8) else { return nil }
        let doc = try SwiftSoup.parse(html)
        return
            """
            Content of page of url:
            \(try doc.text())
            """
    }
}
