import Foundation
import AIAgentMacros
import GeminiSDK

/// Image generation tool using Gemini Models
/// It generates image based on the prompt input
@AITool
public struct GeminiImage {
    public enum Error: Swift.Error {
        case failedToGenerateImage
    }
    @AIModelSchema
    public struct ImageResponse: Encodable {
        /// The image data encoded in png format
        let data: Data
        /// the file name of the generated image
        let fileName: String

        public init(data: Data, fileName: String) {
            self.data = data
            self.fileName = fileName
        }
    }

    let apiKey: String
    let model: String
    let baseFolder: String
    public init(apiKey: String,
                model: String = "gemini-2.0-flash-preview-image-generation",
                baseFolder: String) {
        self.apiKey = apiKey
        self.model = model
        self.baseFolder = baseFolder
    }

    /// A tool to generate image based on the prompt.
    /// - Parameter prompt: the prompt for the image generation
    /// - Returns: Name of the file where the generated image is stored
    func generateImage(prompt: String) async throws -> String {
        let gemini = GeminiSDK(model: model, apiKey: apiKey)
        let contents: [Content] = [.init(parts: [Content.Part.init(text: prompt)])]
        let generationConfig = GeminiRequest.GenerationConfig(responseModalities: [.image, .text])
        let request = GeminiRequest(contents: contents, generationConfig: generationConfig)
        let result = try await gemini.run(request: request)
        guard let data = result.allImages.first else {
            throw Error.failedToGenerateImage
        }
        let fileName = "\(UUID().uuidString).png"
        let fileURL = URL(fileURLWithPath: baseFolder).appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileName
    }
}
