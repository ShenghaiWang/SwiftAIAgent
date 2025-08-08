import Foundation
import GeminiSDK

enum GminiImageGeneration {
    static func run() async throws {
        let gemini = GeminiSDK(model: geminiImageModel, apiKey: geminiAPIKey)
        let result = try await gemini.run(
            prompt: "Hi, can you create a 3d rendered image of a pig with wings and a top hat flying over a happy futuristic scifi city with lots of greenery?",
            modalities: [.image, .text])
        try result.forEach { output in
            if case let .image(data) = output {
                // Specify the file path yourself.
                // Or it will write the image to the folder that the client app sits.
                // For example, if you run it in Xcode, it will be inside a sub folder that under `DerivedData`
                try data.write(to: URL(fileURLWithPath: "image.png"))
            }

            if case let .text(text) = output {
                print(text)
            }
        }
    }
}
