import Foundation

/// Context of an agent
public struct AIAgentContext: Sendable {
    let contenxt: String

    public init(_ contenxt: String) {
        self.contenxt = contenxt
    }
}
