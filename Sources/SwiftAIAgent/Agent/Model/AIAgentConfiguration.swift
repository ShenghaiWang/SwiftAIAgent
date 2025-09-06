import Foundation

/// Configuration for AIAgent execution behavior
public struct AIAgentConfiguration: Sendable {
    let maxToolIterations: Int
    let toolExecutionDelay: Duration

    public init(maxToolIterations: Int = 5, toolExecutionDelay: Duration = .milliseconds(1500)) {
        self.maxToolIterations = maxToolIterations
        self.toolExecutionDelay = toolExecutionDelay
    }

    public static let `default` = AIAgentConfiguration()
}
