import AIAgentMacros
import Foundation

/// The Strategy for the planning
@AIModelSchema
public struct AIStrategy {
    /// the strategy details that will be used in goal planning
    let details: String
}
