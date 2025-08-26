import AIAgentMacros
import Foundation

/// Task that is broken down from a goal
@AIModelSchema
public struct AITask {
    /// A descriptive name of the task
    let name: String
    /// The details a task needs to do
    let details: String

    /// The condition to run this step
    let condition: String?

    /// Run sub tasks in parralel
    let runSubTasksInParallel: Bool?

    /// Sub tasks, an recursive structure to indicate the excute orders of the tasks
    let subTasks: [AISubTask]?
}

// Have to have this as AIModelSchema cannot generate outputSchema recursively
/// Task that is broken down from a goal
@AIModelSchema
public struct AISubTask {
    /// A descriptive name of the task
    let name: String

    /// The details a task needs to do. This is be fed to LLM as prompt.
    let details: String

    /// The condition to run this step
    let condition: String?

    /// Run sub tasks in parralel
    let runSubTasksInParallel: Bool?

    /// The tool names that needed for this sub task. It should come from the function calls that passed into LLM
    let tools: [String]?

    /// Suggested the temperature to be used by LLM, usually between 0.0 and 1.0
    /// The big the number, the creative the LLM would be.
    /// Please assign this value based the level of the creativity that task needs
    let temperature: Float
}

extension AITask: CustomStringConvertible {
    public var description: String {
        """
        Task name:  \(name)
        Details:    \(details)
        Plan:       
        \(subTasks?.compactMap(\.description).joined() ?? "")

        """
    }
}

extension AISubTask: CustomStringConvertible {
    public var description: String {
        """
            Step:       \(name)
            Details:    \(details)
            LLM Setup:  Use \(temperature) for LLM temperature
            Tools:      \(tools?.joined(separator: ",") ?? "")
        
        
        """
    }
}

extension AITask: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ===Task name: \(name)===
        Details: \(details)
        Sub Tasks:
        \(subTasks?.compactMap(\.description).joined() ?? "")

        """
    }
}

extension AISubTask: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
            ===Task name: \(name)===
            Details: \(details)
            Temperature: \(temperature)
            Tools: \(tools?.joined(separator: ",") ?? "")

        
        """
    }
}
