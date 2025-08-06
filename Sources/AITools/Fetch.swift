import Foundation
import AIAgentMacros
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetch tool that retrieve the text content of the url
@AITool
public struct Fetch {
    public init(){}

    /// Fetch the text content of the url
    /// - Parameter url: the url to be fetched
    /// - Returns: the text content of the url
    public func fetch(url: String) async throws -> String? {
        guard let url = URL(string: url) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return String(data: data, encoding: .utf8)
    }
}
