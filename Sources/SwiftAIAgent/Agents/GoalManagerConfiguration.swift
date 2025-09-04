import Foundation

extension GoalManager {
    public struct Configuration {
        let maxClarificationRounds: Int
        let defaultTemperature: Float
        let enableParallelExecution: Bool

        public init(
            maxClarificationRounds: Int = 3,
            defaultTemperature: Float = 0.7,
            enableParallelExecution: Bool = true
        ) {
            self.maxClarificationRounds = maxClarificationRounds
            self.defaultTemperature = defaultTemperature
            self.enableParallelExecution = enableParallelExecution
        }
    }
}
