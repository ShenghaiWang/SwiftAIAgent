public protocol AIAgentTool: Sendable {
    var definition: String? { get }
}

extension AIAgentTool {
    public var definition: String? {
        nil
    }
}
