import Foundation

public struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Codable {
//                struct FunctionCall: Codable {
//                    let id: String?
//                    let name: String?
//                    let args: [String: String]
//                }
                let text: String?
//                let inlineData: Data?
                let functionCall: String?
//                let functionResponse: FunctionResponse?
//                let fileData: FileData?
//                let executableCode: ExecutableCode?
//                let codeExecutionResult: CodeExecutionResult?
            }
            let parts: [Part]
            let role: String
        }

        let content: Content?
//        let finishReason: FinishReason?
//        let safetyRatings: [SafetyRating]?
//        let citationMetadata: CitationMetadata?
        let tokenCount: Int?
//        let groundingAttributions: [GroundingAttribution]?
//        let groundingMetadata: GroundingMetadata?
        let avgLogprobs: Double?
//        let logprobsResult: LogprobsResult?
//        let urlContextMetadata: UrlContextMetadata?
        let index: Int?
    }
    let candidates: [Candidate]
//    let promptFeedback: PromptFeedback?
//    let usageMetadata: UsageMetadata?
    let modelVersion: String?
    let responseId: String?
}

extension GeminiResponse {
    public var text: String {
        candidates.first?.content?.parts.compactMap(\.text).joined(separator: "\n") ?? ""
    }
}

extension Data {
    private func findFunctionCalls(in object: Any, results: inout [String]) {
        if let dict = object as? [String: Any] {
            for (key, value) in dict {
                if key == "functionCall" {
                    if let data = try? JSONSerialization.data(withJSONObject: value, options: []),
                       let str = String(data: data, encoding: .utf8) {
                        results.append(str)
                    }
                } else {
                    findFunctionCalls(in: value, results: &results)
                }
            }
        } else if let array = object as? [Any] {
            for item in array {
                findFunctionCalls(in: item, results: &results)
            }
        }
    }

    func functionCalls() throws -> [String] {
        let jsonObject = try JSONSerialization.jsonObject(with: self)
        var functionCallStrings: [String] = []
        findFunctionCalls(in: jsonObject, results: &functionCallStrings)
        return functionCallStrings
    }
}
