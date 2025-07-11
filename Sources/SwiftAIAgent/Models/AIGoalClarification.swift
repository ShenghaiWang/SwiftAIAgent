import Foundation
import AIAgentMacros

/// Clarification questions to a task
@AIModelOutput
struct AIGoalClarification {
    let questions: [String]
}

extension AIGoalClarification: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        Clarification questions:\n\(questions.joined(separator: "\n"))
        """
    }
}
