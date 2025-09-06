import Foundation

/// Context of an agent
public struct AIAgentContext: Sendable {
    let context: String

    public init(_ contenxt: String) {
        self.context = contenxt
    }
}
