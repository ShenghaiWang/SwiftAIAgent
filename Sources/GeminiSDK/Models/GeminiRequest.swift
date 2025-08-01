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

    public struct Tool: Codable {
        public struct FunctionDeclaration: Codable {
            enum Behavior: String, Codable {
                case unspecified = "UNSPECIFIED"
                case blocking = "BLOCKING"
                case nonBlocking = "NON_BLOCKING"
            }
            public let name: String
            public let description: String
            let behavior: Behavior?
            let parameters: Schema?
            public let parametersJsonSchema: String?
            let response: Schema?
            public let responseJsonSchema: String?

            public init(name: String,
                        description: String,
                        parametersJsonSchema: String?,
                        responseJsonSchema: String? = nil) {
                self.name = name
                self.description = description
                self.behavior = .unspecified
                self.parameters = nil
                self.parametersJsonSchema = parametersJsonSchema
                self.response = nil
                self.responseJsonSchema = responseJsonSchema
            }
        }

        let functionDeclarations: [FunctionDeclaration]?
//        let googleSearchRetrieval: GoogleSearchRetrieval?
//        let codeExecution: CodeExecution?
//        let googleSearch: GoogleSearch?
//        let urlContext: UrlContext?
        public init(functionDeclarations: [FunctionDeclaration]?) {
            self.functionDeclarations = functionDeclarations
        }
    }
    struct ToolConfig: Codable {
        struct FunctionCallingConfig: Codable {
            enum Mode: String, Codable {
                case modeUnspecified = "MODE_UNSPECIFIED"
                case auto = "AUTO"
                case any = "ANY"
                case none = "NONE"
                case validated = "VALIDATED"
            }
            let mode: Mode?
            let allowedFunctionNames: [String]?
        }
        let functionCallingConfig: FunctionCallingConfig?
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
    init(prompt: String, responseJsonSchema: String? = nil, tools: [Tool] = []) {
        self.contents = [.init(parts: [.init(text: prompt)])]
        self.systemInstruction = nil
        if let responseJsonSchema {
            self.generationConfig = .init(responseMimeType: "application/json",
                                          responseJsonSchema: responseJsonSchema)
        } else {
            self.generationConfig = nil
        }
        self.cachedContent = nil
        self.tools = tools
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

extension GeminiRequest.Tool.FunctionDeclaration {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(behavior, forKey: .behavior)

        if let schemaString = parametersJsonSchema {
            let data = Data(schemaString.utf8)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            try container.encode(JSONAny(value: jsonObject), forKey: .parametersJsonSchema)
        }

        if let schemaString = responseJsonSchema {
            let data = Data(schemaString.utf8)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            try container.encode(JSONAny(value: jsonObject), forKey: .responseJsonSchema)
        }
    }
}

extension GeminiRequest {
    var requestingFunctionCalls: Bool {
        if let tools {
            tools.map(\.requestingFunctionCalls).reduce(false, { $0 || $1 })
        } else {
            false
        }
    }
}

extension GeminiRequest.Tool {
    var requestingFunctionCalls: Bool {
        if let functionDeclarations {
            !functionDeclarations.isEmpty
        } else {
            false
        }
    }
}
