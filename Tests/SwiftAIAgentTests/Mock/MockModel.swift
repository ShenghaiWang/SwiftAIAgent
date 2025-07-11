import Foundation
import AIAgentMacros
@testable import SwiftAIAgent

struct MockModel: AIAgentModel {
    func run<T: AIModelOutput>(prompt: String, outputSchema: T.Type) async throws -> AIAgentOutput {
        let result = try await textGeneration(prompt: prompt)
        return AIAgentOutput(result: result)
    }

    private let id: Int

    init(id: Int) {
        self.id = id
    }

    public func run(prompt: String, outputSchema: String?) async throws -> AIAgentOutput {
        let result = try await textGeneration(prompt: prompt)
        return AIAgentOutput(result: result)
    }

    func textGeneration(prompt: String) async throws -> String {
        """
        Agent \(id):
        \(prompt)
        """
    }
}
