import Foundation

public struct GeminiRequest: Codable {
    struct Content: Codable {
        struct Part: Codable {
            let text: String
        }
        let parts: [Part]
    }

    struct GenerationConfig: Decodable {
        let stopSequences: [String]?
        let responseMimeType: String?
        let responseSchema: Schema?
        let responseJsonSchema: String?
        let responseModalities: [Modality]?
        let candidateCount: Int?
        let maxOutputTokens: Int?
        let temperature: Double?
        let topP: Double?
        let topK: Int?
        let seed: Int?
        let presencePenalty: Double?
        let frequencyPenalty: Double?
        let responseLogprobs: Bool?
        let logprobs: Int?
        let enableEnhancedCivicAnswers: Bool?
        let speechConfig: SpeechConfig?
        let thinkingConfig: ThinkingConfig?
        let mediaResolution: MediaResolution?

        struct Schema: Codable {
            enum `Type`: String, Codable {
                case unspecified = "TYPE_UNSPECIFIED"
                case string = "STRING"
                case number = "NUMBER"
                case integer = "INTEGER"
                case bollean = "BOOLEAN"
                case array = "ARRAY"
                case object = "OBJECT"
                case null = "NULL"
            }
            let type: Type
            let format: String?
            let title: String?
            let description: String?
            let nullable: Bool?
            let `enum`: [String]?
            let maxItems: Int?
            let minItems: Int?
            let properties: [String: Schema]?
            let required: [String]?
            let miniProperties: Int?
            let maxProperties: Int?
            let minLength: Int?
            let maxLength: Int?
            let pattern: String?
            let example: String?
            let anyOf: [Schema]?
            let propertyOrdering: [String]?
            let `default`: String?
            let items: [Schema]?
            let minimum: Int?
            let maximum: Int?

            init(type: Type,
                 format: String? = nil,
                 title: String? = nil,
                 description: String? = nil,
                 nullable: Bool? = nil,
                 `enum`: [String]? = nil,
                 maxItems: Int? = nil,
                 minItems: Int? = nil,
                 properties: [String : Schema]? = nil,
                 required: [String]? = nil,
                 miniProperties: Int? = nil,
                 maxProperties: Int? = nil,
                 minLength: Int? = nil,
                 maxLength: Int? = nil,
                 pattern: String? = nil,
                 example: String? = nil,
                 anyOf: [Schema]? = nil,
                 propertyOrdering: [String]? = nil,
                 `default`: String? = nil,
                 items: [Schema]? = nil,
                 minimum: Int? = nil,
                 maximum: Int? = nil
            ) {
                self.type = type
                self.format = format
                self.title = title
                self.description = description
                self.nullable = nullable
                self.enum = `enum`
                self.maxItems = maxItems
                self.minItems = minItems
                self.properties = properties
                self.required = required
                self.miniProperties = miniProperties
                self.maxProperties = maxProperties
                self.minLength = minLength
                self.maxLength = maxLength
                self.pattern = pattern
                self.example = example
                self.anyOf = anyOf
                self.propertyOrdering = propertyOrdering
                self.`default` = `default`
                self.items = items
                self.minimum = minimum
                self.maximum = maximum
            }
        }

        enum Modality: String, Codable {
            case unspecified = "MODALITY_UNSPECIFIED"
            case text = "TEXT"
            case image = "IMAGE"
            case audio = "AUDIO"
        }

        struct SpeechConfig: Codable {
            let voiceConfig: VoiceConfig
            let multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig
            let languageCode: String
        }

        struct VoiceConfig: Codable {
            struct PrebuiltVoiceConfig: Codable {
                let voiceName: String
            }
            let prebuiltVoiceConfig: PrebuiltVoiceConfig?
        }

        struct MultiSpeakerVoiceConfig: Codable {
            struct SpeakerVoiceConfig: Codable {
                let speaker: String
                let voiceConfig: VoiceConfig
            }
            let speakerVoiceConfigs: [SpeakerVoiceConfig]?
        }

        struct ThinkingConfig: Codable {
            let includeThoughts: Bool
            let thinkingBudget: Int?
        }

        enum MediaResolution: String, Codable {
            case unspecified = "MEDIA_RESOLUTION_UNSPECIFIED"
            case low = "MEDIA_RESOLUTION_LOW"
            case medium = "MEDIA_RESOLUTION_MEDIUM"
            case high = "MEDIA_RESOLUTION_HIGH"
        }

        init(stopSequences: [String]? = nil,
             responseMimeType: String? = nil,
             responseSchema: Schema? = nil,
             responseJsonSchema: String? = nil,
             responseModalities: [Modality]? = nil,
             candidateCount: Int? = nil,
             maxOutputTokens: Int? = nil,
             temperature: Double? = nil,
             topP: Double? = nil,
             topK: Int? = nil,
             seed: Int? = nil,
             presencePenalty: Double? = nil,
             frequencyPenalty: Double? = nil,
             responseLogprobs: Bool? = nil,
             logprobs: Int? = nil,
             enableEnhancedCivicAnswers: Bool? = nil,
             speechConfig: SpeechConfig? = nil,
             thinkingConfig: ThinkingConfig? = nil,
             mediaResolution: MediaResolution? = nil) {
            self.stopSequences = stopSequences
            self.responseMimeType = responseMimeType
            self.responseSchema = responseSchema
            self.responseJsonSchema = responseJsonSchema
            self.responseModalities = responseModalities
            self.candidateCount = candidateCount
            self.maxOutputTokens = maxOutputTokens
            self.temperature = temperature
            self.topP = topP
            self.topK = topK
            self.seed = seed
            self.presencePenalty = presencePenalty
            self.frequencyPenalty = frequencyPenalty
            self.responseLogprobs = responseLogprobs
            self.logprobs = logprobs
            self.enableEnhancedCivicAnswers = enableEnhancedCivicAnswers
            self.speechConfig = speechConfig
            self.thinkingConfig = thinkingConfig
            self.mediaResolution = mediaResolution
        }
    }
    struct Tool: Codable {
        // TODO:
    }
    struct ToolConfig: Codable {
        // TODO:
    }

    struct SafetySetting: Codable {
        // TODO:
    }

    let contents: [Content]
    let systemInstruction: Content?
    let generationConfig: GenerationConfig?
    let cachedContent: String?
    let tools: [Tool]?
    let toolConfig: ToolConfig?
    let safetySettings: [SafetySetting]?
}

extension GeminiRequest {
    init(prompt: String, responseJsonSchema: String? = nil) {
        self.contents = [.init(parts: [.init(text: prompt)])]
        self.systemInstruction = nil
        self.generationConfig = .init(responseMimeType: "application/json",
                                      responseJsonSchema: responseJsonSchema)
        self.cachedContent = nil
        self.tools = nil
        self.toolConfig = nil
        self.safetySettings = nil
    }
}

extension GeminiRequest.GenerationConfig: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(responseMimeType, forKey: .responseMimeType)

        if let schemaString = responseJsonSchema {
            let data = Data(schemaString.utf8)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            try container.encode(JSONAny(value: jsonObject), forKey: .responseJsonSchema)
        }
    }
}
