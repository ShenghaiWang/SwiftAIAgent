import Foundation
import AIAgentMacros

/// A wrapper type for all types of output from LLM
public enum AIAgentOutput: Sendable {
    case text(String)
    case functionCalls([String])
    case strongTypedValue(Sendable)
    case empty
}

extension AIAgentOutput {
    public var output: String {
        switch self {
        case let .text(result):
            result
        case let .functionCalls(result):
            result.joined(separator: "||")
        case let .strongTypedValue(result):
            "\(result)"
        case .empty:
            ""
        }
    }
}


extension Array where Element == AIAgentOutput {
    public var firstText: AIAgentOutput? {
        allTextOutputs.first
    }

    public var allTextOutputs: [AIAgentOutput] {
        filter { if case .text = $0 { true } else { false } }
    }

    public var allTexts: [String] {
        compactMap { if case let .text(text) = $0 { text } else { nil } }
    }

    public var allFunctionCallOutputs: [AIAgentOutput] {
        filter { if case .functionCalls = $0 { true } else { false } }
    }

    public var allFunctionCalls: [String] {
        compactMap { if case let .functionCalls(calls) = $0 { calls } else { nil } }
            .flatMap { $0 }
    }

    public var allStrongTypedValues: [AIAgentOutput] {
        filter { if case .strongTypedValue = $0 { true } else { false } }
    }
}
