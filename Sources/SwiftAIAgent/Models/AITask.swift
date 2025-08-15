import Foundation
import AIAgentMacros

/// Task that is broken down from a goal
@AIModelSchema
struct AITask {
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
struct AISubTask {
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
}

extension AITask: CustomStringConvertible {
    public var description: String {
        """
        ===Task name: \(name)===
        Details: \(details)
        Sub Tasks:\n\(subTasks?.compactMap(\.description).joined() ?? "\n")
        
        """
    }
}


extension AISubTask: CustomStringConvertible {
    public var description: String {
        """
        ===Task name: \(name)===
        Details: \(details)
        Tools: \(tools?.joined(separator: ",") ?? "")
        
        """
    }
}
