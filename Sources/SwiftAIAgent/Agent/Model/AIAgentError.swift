import Foundation

/// Errors that can occur during AIAgent execution
public enum AIAgentError: Error {
    case maxIterationsReached(lastResult: [AIAgentOutput])
    case toolExecutionFailed(String)
    case invalidConfiguration
}
