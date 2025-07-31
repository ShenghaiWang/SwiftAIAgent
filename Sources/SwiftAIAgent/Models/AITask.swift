import Foundation
import AIAgentMacros

/// Task that is broken down from a goal
@AIModelOutput
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

// Have to have this as AIModelOutput cannot generate outputSchema recursively
/// Task that is broken down from a goal
@AIModelOutput
struct AISubTask {
    /// A descriptive name of the task
    let name: String
    /// The details a task needs to do
    let details: String

    /// The condition to run this step
    let condition: String?

    /// Run sub tasks in parralel
    let runSubTasksInParallel: Bool?
}

extension AITask: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        
        ===Task name: \(name)===
        Details: \(details)
        Sub Tasks: \(subTasks?.compactMap(\.debugDescription).joined() ?? "")
        
        """
    }
}


extension AISubTask: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        
        ===Task name: \(name)===
        Details: \(details)
        
        """
    }
}

extension AITask {
    func workflow(for goal: String, with model: AIAgentModel) throws -> Workflow {
        guard let subTasks else {
            throw GoalManager.Error.noPlan
        }
        let steps = subTasks.map({ task in
            let context = AIAgentContext("<finalGoal>\(goal)</finalGoal>")
            let agent = AIAgent(title: task.name,
                                model: model,
                                context: context,
                                instruction: task.details)
            return Workflow.Step.single(agent)
        })
        return Workflow(step: .sequence(steps))
    }
}
