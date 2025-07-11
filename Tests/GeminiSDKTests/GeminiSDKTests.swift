import Testing
@testable import GeminiSDK
import Foundation
import AIAgentMacros

/// Task that is broken down from a goal
@AIModelOutput
struct AITask {
    /// A descriptive name of the task
    let name: String
    /// The details a task needs to do
    let details: String
}

/// Tasks that is broken down from a goal
@AIModelOutput
struct AITasks {
    /// Tasks
    let tasks: [AITask]
}

@Test
func testAPICall() async throws {
//    let sdk = GeminiSDK(model: "gemini-2.5-flash",
//                        apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
//    let response = try await sdk.textGeneration(prompt: "List a few popular cookie recipes, and include the amounts of ingredients.", responseSchema: AITasks.self)
//    #expect(!response.tasks.isEmpty)
}
