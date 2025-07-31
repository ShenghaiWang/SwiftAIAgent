import Foundation

/// Workflow of the agent system
public struct Workflow {
    /// Step of a workflow
    public indirect enum Step: Sendable {
        /// Sigle step
        case single(AIAgent)
        /// Sequence step
        case sequence([Step])
        /// Parrallel step
        case parrallel([Step])
        /// Conditional step
        case conditional(@Sendable (AIAgentOutput) -> Bool, Step)
    }

    let step: Step

    /// Initialise a workflow
    /// - Parameters:
    ///  - step: the step to execute in the workflow, which is a recusive definition of step enum.
    public init(step: Step) {
        self.step = step
    }

    /// Run the work flow
    /// - Parameters:
    ///  - prompt: The prompt to start the workflow
    /// - Returns: The result of the workflow run
    /// - Throws: Any error that encountered in executing the workflow
    public func run(prompt: String) async throws -> AIAgentOutput {
        try await step.run(prompt: prompt)
    }
}

extension Workflow.Step {
    func run(prompt: String) async throws -> AIAgentOutput {
        switch self {
        case let .single(agent): try await agent.run(prompt: prompt)
        case let .sequence(steps): try await runSequence(steps: steps, prompt: prompt)
        case let .parrallel(steps): try await runParrallel(steps: steps, prompt: prompt)
        case let .conditional(condition, step): try await runConditional(condition: condition, step: step, prompt: prompt)
        }
    }

    func runSequence(steps: [Self], prompt: String) async throws -> AIAgentOutput {
        try await steps.async.reduce(AIAgentOutput(result: prompt)) { result, step in
            try await step.run(prompt: result.output)
        }
    }

    func runParrallel(steps: [Self], prompt: String) async throws -> AIAgentOutput {
        try await withThrowingTaskGroup(of: AIAgentOutput.self) { group in
            for step in steps {
                group.addTask { try await step.run(prompt: prompt) }
            }
            var outputs: [AIAgentOutput] = []
            for try await output in group {
                outputs.append(output)
            }
            return AIAgentOutput(result: outputs.map(\.output).joined(separator: "\n"))
        }
    }

    func runConditional(condition: @Sendable (AIAgentOutput) -> Bool, step: Self, prompt: String) async throws -> AIAgentOutput {
        condition(.init(result: prompt))
            ? try await step.run(prompt: prompt)
            : .empty
    }
}
