import Foundation

public enum GeminiOutput: Sendable {
    case text(String)
    case functionCalls([String])
    case strongTypedValue(Sendable)
    case image(Data)
    case audio(Data)
}

extension Array where Element == GeminiOutput {
    public var firstText: GeminiOutput? {
        allTextOutputs.first
    }

    public var allTextOutputs: [GeminiOutput] {
        filter { if case .text = $0 { true } else { false } }
    }

    public var allTexts: [String] {
        compactMap { if case let .text(text) = $0 { text } else { nil } }
    }

    public var allFunctionCallOutputs: [GeminiOutput] {
        filter { if case .functionCalls = $0 { true } else { false } }
    }

    public var allFunctionCalls: [String] {
        compactMap { if case let .functionCalls(calls) = $0 { calls } else { nil } }
            .flatMap { $0 }
    }
}
