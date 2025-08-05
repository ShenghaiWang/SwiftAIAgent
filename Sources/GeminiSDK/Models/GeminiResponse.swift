import Foundation

public struct GeminiResponse: Decodable {
    public struct Candidate: Decodable {
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
    public struct PromptFeedback: Decodable {
        public enum BlockReason: String, Decodable {
            case unspecified = "BLOCK_REASON_UNSPECIFIED"
            case safety = "SAFETY"
            case other = "OTHER"
            case blocklist = "BLOCKLIST"
            case prohibitedContent = "PROHIBITED_CONTENT"
            case imageSafety = "IMAGE_SAFETY"
        }
        public struct SafetyRating: Decodable {
            let category: HarmCategory
            let probability: HarmProbability
            let blocked: Bool
        }
        let blockReason: BlockReason
        let safetyRatings: SafetyRating
    }
    public struct UsageMetadata: Decodable {
        public struct ModalityTokenCount: Decodable {
            let modality: GeminiModality
            let tokenCount: Int
        }
        let promptTokenCount: Int?
        let cachedContentTokenCount: Int?
        let candidatesTokenCount: Int?
        let toolUsePromptTokenCount: Int?
        let thoughtsTokenCount: Int?
        let totalTokenCount: Int?
        let promptTokensDetails: [ModalityTokenCount]?
        let cacheTokensDetails: [ModalityTokenCount]?
        let candidatesTokensDetails: [ModalityTokenCount]?
        let toolUsePromptTokensDetails: [ModalityTokenCount]?
    }
    let candidates: [Candidate]
    let promptFeedback: PromptFeedback?
    let usageMetadata: UsageMetadata?
    let modelVersion: String?
    let responseId: String?
}

extension GeminiResponse {
    public var text: String? {
        candidates.first?.content?.parts.compactMap(\.text).joined(separator: "\n")
    }

    public var inlineData: Content.Part.InlineData? {
        candidates.first?.content?.parts.compactMap(\.inlineData).first
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
