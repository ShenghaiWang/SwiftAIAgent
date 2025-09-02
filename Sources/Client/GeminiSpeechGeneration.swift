import Foundation
import GeminiSDK

enum GminiSpeechGeneration {
    static func run() async throws {
        let gemini = GeminiSDK(model: geminiTTSModel, apiKey: geminiAPIKey)
        let speechConfig = GeminiRequest.GenerationConfig.SpeechConfig(
            voiceConfig: .init(prebuiltVoiceConfig: .init(voiceName: .Achernar))
        )
        let request = GeminiRequest(
            contents: [.init(parts: [.init(text: "Say cheerfully: Have a wonderful day!")])],
            generationConfig: .init(
                responseModalities: [.audio],
                speechConfig: speechConfig
            )
        )
        let result = try await gemini.run(request: request)
        try result.forEach { output in
            if case let .audio(data) = output {
                // Specify the file path yourself.
                // Or it will write the image to the folder that the client app sits.
                // For example, if you run it in Xcode, it will be inside a sub folder that under `DerivedData`
                // need to install ffmpeg and run command `ffmpeg -f s16le -ar 24000 -ac 1 -i speech.pcm speech.wav`
                // to convert pcm to wav file to play it
                try data.write(to: URL(fileURLWithPath: "speech.pcm"))
            }

            if case let .text(text) = output {
                print(text)
            }
        }
    }
}
