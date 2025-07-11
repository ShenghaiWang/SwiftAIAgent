import Foundation
import AIAgentMacros

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
