import Foundation

public struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String
            }
            let parts: [Part]
            let role: String
        }
        let content: Content
        let finishReason: String
        let index: Int
    }
    let candidates: [Candidate]
}


extension GeminiResponse {
    public var text: String {
        candidates.first?.content.parts.map(\.text).joined(separator: "\n") ?? ""
    }
}
