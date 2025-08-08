import Foundation
import AIAgentMacros
@testable import SwiftAIAgent

struct MockModel: AIAgentModel {
    var description: String { "" }
    
    func run(prompt: String,
             outputSchema: AIModelSchema.Type,
             toolSchemas: [String]? = nil,
             modalities: [Modality]? = nil,
             inlineData: InlineData? = nil) async throws -> [AIAgentOutput] {
        let result = try await textGeneration(prompt: prompt)
        return [.text(result)]
    }

    private let id: Int

    init(id: Int) {
        self.id = id
    }

    public func run(prompt: String,
                    outputSchema: String?,
                    toolSchemas: [String]? = nil,
                    modalities: [Modality]? = nil,
                    inlineData: InlineData? = nil) async throws -> [AIAgentOutput] {
        let result = try await textGeneration(prompt: prompt)
        return [.text(result)]
    }

    func textGeneration(prompt: String) async throws -> String {
        """
        Agent \(id):
        \(prompt)
        """
    }
}
