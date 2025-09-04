import Foundation

extension GoalManager {
    public enum Error: Swift.Error, LocalizedError {
        case noPlan
        case wrongResponseFormatFromAI
        case needClarification(questions: [String])
        case invalidConfiguration(String)
        case executionFailed(String)
        case modelSelectionFailed

        public var errorDescription: String? {
            switch self {
                case .noPlan:
                    return "No execution plan could be generated for the goal"
                case .wrongResponseFormatFromAI:
                    return "AI response format was invalid or unexpected"
                case .needClarification(let questions):
                    return "Goal requires clarification: \(questions.joined(separator: ", "))"
                case .invalidConfiguration(let message):
                    return "Invalid configuration: \(message)"
                case .executionFailed(let message):
                    return "Execution failed: \(message)"
                case .modelSelectionFailed:
                    return "Failed to select appropriate model for task execution"
            }
        }
    }
}
