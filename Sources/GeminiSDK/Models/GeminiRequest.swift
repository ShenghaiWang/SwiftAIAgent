import Foundation

public struct GeminiRequest: Codable {
    public struct GenerationConfig: Decodable {
        let stopSequences: [String]?
        let responseMimeType: String?
        let responseSchema: Schema?
        let responseJsonSchema: String?
        let responseModalities: [GeminiModality]?
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

        public struct SpeechConfig: Codable {
            let voiceConfig: VoiceConfig?
            let multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig?
            let languageCode: String?

            public init(
                voiceConfig: VoiceConfig? = nil,
                multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig? = nil,
                languageCode: String? = nil
            ) {
                self.voiceConfig = voiceConfig
                self.multiSpeakerVoiceConfig = multiSpeakerVoiceConfig
                self.languageCode = languageCode
            }
        }

        public struct VoiceConfig: Codable {
            public struct PrebuiltVoiceConfig: Codable {
                let voiceName: VoiceName
                public init(voiceName: VoiceName) {
                    self.voiceName = voiceName
                }
            }
            let prebuiltVoiceConfig: PrebuiltVoiceConfig?
            public init(prebuiltVoiceConfig: PrebuiltVoiceConfig?) {
                self.prebuiltVoiceConfig = prebuiltVoiceConfig
            }
        }

        public struct MultiSpeakerVoiceConfig: Codable {
            public struct SpeakerVoiceConfig: Codable {
                let speaker: String
                let voiceConfig: VoiceConfig
            }
            let speakerVoiceConfigs: [SpeakerVoiceConfig]?
            public init(speakerVoiceConfigs: [SpeakerVoiceConfig]?) {
                self.speakerVoiceConfigs = speakerVoiceConfigs
            }
        }

        public struct ThinkingConfig: Codable {
            let includeThoughts: Bool
            let thinkingBudget: Int?
        }

        public enum MediaResolution: String, Codable {
            case unspecified = "MEDIA_RESOLUTION_UNSPECIFIED"
            case low = "MEDIA_RESOLUTION_LOW"
            case medium = "MEDIA_RESOLUTION_MEDIUM"
            case high = "MEDIA_RESOLUTION_HIGH"
        }

        public init(
            stopSequences: [String]? = nil,
            responseMimeType: String? = nil,
            responseSchema: Schema? = nil,
            responseJsonSchema: String? = nil,
            responseModalities: [GeminiModality]? = nil,
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
            mediaResolution: MediaResolution? = nil
        ) {
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
            let name: String
            let description: String
            let behavior: Behavior?
            let parameters: Schema?
            let parametersJsonSchema: String?
            let response: Schema?
            let responseJsonSchema: String?

            public init(
                name: String,
                description: String,
                parametersJsonSchema: String?,
                responseJsonSchema: String? = nil,
                parameters: Schema? = nil,
                response: Schema? = nil
            ) {
                self.name = name
                self.description = description
                self.behavior = .unspecified
                self.parametersJsonSchema = parametersJsonSchema
                self.responseJsonSchema = responseJsonSchema
                self.parameters = parameters
                self.response = response
            }
        }

        public struct GoogleSearchRetrieval: Codable {
            public enum Mode: String, Codable {
                case unspecified = "MODE_UNSPECIFIED"
                case dynamic = "MODE_DYNAMIC"
            }
            let mode: Mode
            let dynamicThreshold: Double
        }

        public struct CodeExecution: Codable {
        }

        public struct GoogleSearch: Codable {
            public struct Inteval: Codable {
                let startTime: String
                let endTime: String
            }
            let timeRangeFilter: Inteval
        }

        public struct UrlContext: Codable {
        }

        let functionDeclarations: [FunctionDeclaration]?
        let googleSearchRetrieval: GoogleSearchRetrieval?
        let codeExecution: CodeExecution?
        let googleSearch: GoogleSearch?
        let urlContext: UrlContext?
        public init(
            functionDeclarations: [FunctionDeclaration]? = nil,
            googleSearchRetrieval: GoogleSearchRetrieval? = nil,
            codeExecution: CodeExecution? = nil,
            googleSearch: GoogleSearch? = nil,
            urlContext: UrlContext? = nil
        ) {
            self.functionDeclarations = functionDeclarations
            self.googleSearchRetrieval = googleSearchRetrieval
            self.codeExecution = codeExecution
            self.googleSearch = googleSearch
            self.urlContext = urlContext
        }
    }
    public struct ToolConfig: Codable {
        public struct FunctionCallingConfig: Codable {
            public enum Mode: String, Codable {
                case unspecified = "MODE_UNSPECIFIED"
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

    public struct SafetySetting: Codable {
        let category: HarmCategory
        let threshold: HarmBlockThreshold
    }

    let contents: [Content]
    let systemInstruction: Content?
    let generationConfig: GenerationConfig?
    let cachedContent: String?
    let tools: [Tool]?
    let toolConfig: ToolConfig?
    let safetySettings: [SafetySetting]?

    public init(
        contents: [Content],
        systemInstruction: Content? = nil,
        generationConfig: GenerationConfig? = nil,
        cachedContent: String? = nil,
        tools: [Tool]? = nil,
        toolConfig: ToolConfig? = nil,
        safetySettings: [SafetySetting]? = nil
    ) {
        self.contents = contents
        self.systemInstruction = systemInstruction
        self.generationConfig = generationConfig
        self.cachedContent = cachedContent
        self.tools = tools
        self.toolConfig = toolConfig
        self.safetySettings = safetySettings
    }
}

extension GeminiRequest.GenerationConfig: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(stopSequences, forKey: .stopSequences)
        try container.encodeIfPresent(responseMimeType, forKey: .responseMimeType)
        if let schemaString = responseJsonSchema {
            let data = Data(schemaString.utf8)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            try container.encode(JSONAny(value: jsonObject), forKey: .responseJsonSchema)
        }
        try container.encodeIfPresent(responseModalities, forKey: .responseModalities)
        try container.encodeIfPresent(candidateCount, forKey: .candidateCount)
        try container.encodeIfPresent(maxOutputTokens, forKey: .maxOutputTokens)
        try container.encodeIfPresent(temperature, forKey: .temperature)
        try container.encodeIfPresent(topP, forKey: .topP)
        try container.encodeIfPresent(topK, forKey: .topK)
        try container.encodeIfPresent(seed, forKey: .seed)
        try container.encodeIfPresent(presencePenalty, forKey: .presencePenalty)
        try container.encodeIfPresent(frequencyPenalty, forKey: .frequencyPenalty)
        try container.encodeIfPresent(responseLogprobs, forKey: .responseLogprobs)
        try container.encodeIfPresent(logprobs, forKey: .logprobs)
        try container.encodeIfPresent(
            enableEnhancedCivicAnswers,
            forKey: .enableEnhancedCivicAnswers
        )
        try container.encodeIfPresent(speechConfig, forKey: .speechConfig)
        try container.encodeIfPresent(thinkingConfig, forKey: .thinkingConfig)
        try container.encodeIfPresent(mediaResolution, forKey: .mediaResolution)
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
        guard let tools else { return false }
        return tools.map(\.requestingFunctionCalls).reduce(false, { $0 || $1 })
    }
}

extension GeminiRequest.Tool {
    var requestingFunctionCalls: Bool {
        guard let functionDeclarations else { return false }
        return !functionDeclarations.isEmpty
    }
}
