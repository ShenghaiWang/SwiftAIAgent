import Foundation

public struct GeminiResponse: Decodable {
    public struct Candidate: Decodable {
        public enum FinishReason: String, Decodable {
            case unspecified = "FINISH_REASON_UNSPECIFIED"
            case stop = "STOP"
            case maxTokents = "MAX_TOKENS"
            case safety = "SAFETY"
            case recitation = "RECITATION"
            case language = "LANGUAGE"
            case other = "OTHER"
            case blocklist = "BLOCKLIST"
            case prohibitedContent = "PROHIBITED_CONTENT"
            case spii = "SPII"
            case malformedFunctionCall = "MALFORMED_FUNCTION_CALL"
            case imageSafety = "IMAGE_SAFETY"
            case unexpectedToolCall = "UNEXPECTED_TOOL_CALL"
        }
        public struct CitationMetadata: Decodable {
            public struct CitationSource: Decodable {
                let startIndex: Int
                let endIndex: Int
                let uri: String?
                let license: String?
            }
            let citationSources: [CitationSource]
        }
        public struct GroundingAttribution: Decodable {
            public struct AttributionSourceId: Decodable {
                public struct GroundingPassageId: Decodable {
                    let passageId: Int
                    let partIndex: Int
                }
                public struct SemanticRetrieverChunk: Decodable {
                    let source: String
                    let chunk: String
                }
                let groundingPassage: GroundingPassageId?
                let semanticRetrieverChunk: SemanticRetrieverChunk?
            }
            let sourceId: AttributionSourceId
            let content: Content
        }
        public struct GroundingMetadata: Decodable {
            public struct GroundingChunk: Decodable {
                public struct Web: Decodable {
                    let uri: String
                    let title: String
                }
                let chunk_type: Web?
            }
            public struct GroundingSupport: Decodable {
                public struct Segment: Decodable {
                    let partIndex: Int
                    let startIndex: Int
                    let endIndex: Int
                    let text: String
                }
                let groundingChunkIndices: [Int]
                let confidenceScores: [Double]
                let segment: Segment
            }
            public struct SearchEntryPoint: Decodable {
                let renderedContent: String
                let sdkBlob: String
            }
            public struct RetrievalMetadata: Decodable {
                let googleSearchDynamicRetrievalScore: Double
            }
            let groundingChunks: [GroundingChunk]?
            let groundingSupports: [GroundingSupport]?
            let webSearchQueries: [String]?
            let searchEntryPoint: SearchEntryPoint?
            let retrievalMetadata: RetrievalMetadata?
        }
        public struct LogprobsResult: Decodable {
            public struct Candidate: Decodable {
                let token: String
                let tokenId: Int
                let logProbability: Double
            }
            public struct TopCandidates: Decodable {
                let candidates: [Candidate]
            }
            let topCandidates: [TopCandidates]
            let chosenCandidates: Candidate
        }
        public struct UrlContextMetadata: Decodable {
            public struct UrlMetadata: Decodable {
                public enum UrlRetrievalStatus: String, Decodable {
                    case unspecified = "URL_RETRIEVAL_STATUS_UNSPECIFIED"
                    case success = "URL_RETRIEVAL_STATUS_SUCCESS"
                    case error = "URL_RETRIEVAL_STATUS_ERROR"
                }
                let retrievedUrl: String
                let urlRetrievalStatus: UrlRetrievalStatus
            }
            let urlMetadata: [UrlMetadata]
        }
        let content: Content?
        let finishReason: FinishReason?
        let safetyRatings: [SafetyRating]?
        let citationMetadata: CitationMetadata?
        let tokenCount: Int?
        let groundingAttributions: [GroundingAttribution]?
        let groundingMetadata: GroundingMetadata?
        let avgLogprobs: Double?
        let logprobsResult: LogprobsResult?
        let urlContextMetadata: UrlContextMetadata?
        let index: Int?
    }
    public struct PromptFeedback: Decodable {
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
                        let str = String(data: data, encoding: .utf8)
                    {
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
