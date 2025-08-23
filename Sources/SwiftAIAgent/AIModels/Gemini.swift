import AIAgentMacros
import Foundation
import GeminiSDK

extension GeminiSDK: AIAgentModel {
    public var description: String {
        """
        LLM from Google that can be used for chat, image generation and audio generation.
        """
    }

    /// Rum prompt with LLM with structured output schema
    /// - Parameters:
    ///  - prompt: the prompt to be sent to Gemini
    ///  - outputSchema: the output schema in json string format
    ///  - toolSchemas: the tool schemas that can be used
    ///  - modalities: the modalities of the generated content
    ///  - inlineData: the data uploaded to work with the prompt
    ///  - temperature: the creativity level of the model
    /// - Returns: A wrapper of all types of output of Gemini
    public func run(
        prompt: String,
        outputSchema: String? = nil,
        toolSchemas: [String]? = nil,
        modalities: [Modality]? = [.text],
        inlineData: InlineData? = nil,
        temperature: Float? = nil,
    ) async throws -> [AIAgentOutput] {
        let functionDeclarations = toolSchemas?.compactMap(\.functionDeclaration) ?? []
        let request = GeminiRequest.request(
            for: prompt,
            responseJsonSchema: outputSchema,
            tools: [.init(functionDeclarations: functionDeclarations)],
            modalities: modalities,
            inlineData: inlineData,
            temperature: temperature)
        let result = try await run(request: request)
        return result.aiAgentOutput
    }

    /// Rum prompt with LLM with structured output schema
    /// - Parameters:
    ///  - prompt: the prompt to be sent to Gemini
    ///  - outputSchema: the json schema of the expected output in Swift Strong type
    ///  - toolSchemas: the tool schemas that can be used
    ///  - modalities: the modalities of the generated content
    ///  - inlineData: the data uploaded to work with the prompt
    ///  - temperature: the creativity level of the model
    /// - Returns: A wrapper of all types of output of Gemini that contains strong typed value
    public func run(
        prompt: String,
        outputSchema: AIModelSchema.Type,
        toolSchemas: [String]? = nil,
        modalities: [Modality]? = [.text],
        inlineData: InlineData? = nil,
        temperature: Float? = nil,
    ) async throws -> [AIAgentOutput] {
        let result = try await run(
            prompt: prompt,
            outputSchema: outputSchema.outputSchema,
            toolSchemas: toolSchemas,
            modalities: modalities,
            inlineData: inlineData,
            temperature: temperature)
        if case let .text(jsonString) = result.firstText {
            let value = try JSONDecoder().decode(outputSchema, from: Data(jsonString.utf8))
            return [.strongTypedValue(value)] + result.allFunctionCallOutputs
        }
        throw Error.invalidData
    }
}

extension String {
    var functionDeclaration: GeminiRequest.Tool.FunctionDeclaration? {
        /// parsing name, description, parametersJsonSchema from the string to initiate FunctionDeclaration
        guard let data = self.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        guard let name = json["name"] as? String,
            let description = json["description"] as? String
        else {
            return nil
        }
        // parametersJsonSchema can be a dictionary or a string
        var parametersJsonSchemaString: String?
        if let schemaDict = json["parametersJsonSchema"] as? [String: Any],
            let schemaData = try? JSONSerialization.data(
                withJSONObject: schemaDict, options: .sortedKeys),
            let schemaString = String(data: schemaData, encoding: .utf8)
        {
            parametersJsonSchemaString = schemaString
        } else if let schemaString = json["parametersJsonSchema"] as? String {
            parametersJsonSchemaString = schemaString
        }
        guard let parametersJsonSchema = parametersJsonSchemaString else {
            return nil
        }
        return GeminiRequest.Tool.FunctionDeclaration(
            name: name,
            description: description,
            parametersJsonSchema: parametersJsonSchema
        )
    }
}

extension GeminiOutput {
    var aiAgentOutput: AIAgentOutput? {
        switch self {
        case let .functionCalls(calls): .functionCalls(calls)
        case let .strongTypedValue(value): .strongTypedValue(value)
        case let .text(text): .text(text)
        case let .image(data): .image(data)
        case let .audio(data): .audio(data)
        }
    }
}

extension Array where Element == GeminiOutput {
    var aiAgentOutput: [AIAgentOutput] {
        compactMap(\.aiAgentOutput)
    }
}

extension GeminiRequest {
    static func request(
        for prompt: String,
        responseJsonSchema: String?,
        tools: [Tool]?,
        modalities: [Modality]?,
        inlineData: InlineData?,
        temperature: Float?,
    ) -> GeminiRequest {
        let contents: [Content] =
            if let inlineData {
                [.init(parts: [Content.Part.init(text: prompt, inlineData: inlineData.inlineData)])]
            } else {
                [.init(parts: [Content.Part.init(text: prompt)])]
            }
        let temperature: Double? =
            if let temperature {
                Double(temperature) * 2  // Map temperature range 0...1 to 0...2 for Gemini
            } else {
                nil
            }
        let generationConfig: GenerationConfig =
            if let responseJsonSchema {
                .init(
                    responseMimeType: "application/json",
                    responseJsonSchema: responseJsonSchema,
                    responseModalities: modalities?.map(\.modality),
                    temperature: temperature
                )
            } else {
                .init(
                    responseModalities: modalities?.map(\.modality),
                    temperature: temperature)
            }
        return GeminiRequest(contents: contents, generationConfig: generationConfig, tools: tools)
    }
}

extension InlineData {
    var inlineData: Content.Part.InlineData {
        .init(mimeType: mimeType, data: data)
    }
}

extension Modality {
    var modality: GeminiModality {
        switch self {
        case .text: .text
        case .image: .image
        case .audio: .audio
        case .unspecified: .unspecified
        }
    }
}
