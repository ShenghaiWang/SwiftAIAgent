import Foundation
import AIAgentMacros

/// A wrapper type for all types of output from LLM
public struct AIAgentOutput: Sendable {
    public let result: Sendable
}

extension AIAgentOutput {
    static let empty = AIAgentOutput(result: "")
}

extension AIAgentOutput {
    public var output: String {
        "\(result)"
    }
}
