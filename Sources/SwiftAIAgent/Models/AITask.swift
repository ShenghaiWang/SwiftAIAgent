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

    /// The tool names that needed for this sub task. It should come from the function calls that passed into LLM
    let tools: [String]?
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
    func workflow(for goal: String,
                  models: [AIAgentModel],
                  tools: [any AIAgentTool],
                  mcpServers: [MCPServer]) throws -> Workflow {
        guard let subTasks,
                let model = models.first else { // TODO: select model based on planning
            throw GoalManager.Error.noPlan
        }
        let steps = subTasks.map({ task in // TODO: Smarter workflow generation, sequence or paralletl? tools/mcpserver assignment etc.
            let context = AIAgentContext("<finalGoal>\(goal)</finalGoal>")
            let taskTools = tools.filter { !Set($0.methodMap.keys).union(Set(task.tools ?? [])).isEmpty }
            let taskMCPServers: [MCPServer] = [] // TODO: refine mcp servers
            let agent = AIAgent(title: task.name,
                                model: model,
                                tools: taskTools,
                                mcpServers: taskMCPServers,
                                context: context,
                                instruction: task.details)
            // TODO: Adjust data flow input if needed
            return Workflow.Step.single(agent)
        })
        return Workflow(step: .sequence(steps))
    }
}
