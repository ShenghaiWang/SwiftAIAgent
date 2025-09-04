import Foundation

extension GoalManager {
    public enum ExecutionState {
        case idle
        case clarifying
        case planning
        case executing
        case completed
        case failed(Error)
    }
}
