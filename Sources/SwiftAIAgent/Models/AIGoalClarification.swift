import Foundation
import AIAgentMacros

/// Clarification questions to a task
@AIModelSchema
struct AIGoalClarification {
    let questions: [String]
}

extension AIGoalClarification: CustomStringConvertible {
    public var description: String {
        """
        Clarification questions:\n\(questions.joined(separator: "\n"))
        """
    }
}
