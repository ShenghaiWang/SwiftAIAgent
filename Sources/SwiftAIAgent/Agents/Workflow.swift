import Foundation

public struct Workflow {
    public indirect enum Step: Sendable {
        case single(AIAgent)
        case sequence([Step])
        case parrallel([Step])
        case conditional(@Sendable (AIAgentOutput) -> Bool, Step)
    }

    let step: Step

    public init(step: Step) {
        self.step = step
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

extension Workflow {
    public func run(prompt: String) async throws -> AIAgentOutput {
        try await step.run(prompt: prompt)
    }
}
