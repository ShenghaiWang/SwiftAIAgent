import Foundation
import Logging

LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = .debug
    return handler
}

let geminiAPIKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
let geminiModel = "gemini-2.5-flash"
let geminiImageModel = "gemini-2.0-flash-preview-image-generation"
let geminiTTSModel = "gemini-2.5-flash-preview-tts"

// Workflow example
//try await ManualFlow.run()
try await AutoWorkflow.run(goal: .autoSlides)

// Gemini Speech Generation
//try await GminiSpeechGeneration.run()
