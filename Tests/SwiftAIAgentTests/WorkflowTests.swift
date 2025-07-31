import Testing
@testable import SwiftAIAgent

@Suite("Testing workflow")
struct WorkflowTests {
    @Test
    func testSingleWorkflow() async throws {
        let agent = AIAgent(title: "", model: MockModel(id: 1))
        let step = Workflow.Step.single(agent)
        let workflow = Workflow(step: step)
        let result = try await workflow.run(prompt: "hello world")
        print(result)
        #expect(result.allTexts.joined(separator: "\n") ==
            """
            Agent 1:
            hello world
            """)
    }

    @Test
    func testSequenceWorkflow() async throws {
        let agent1 = AIAgent(title: "", model: MockModel(id: 1))
        let agent2 = AIAgent(title: "", model: MockModel(id: 2))
        let step = Workflow.Step.sequence([.single(agent1), .single(agent2)])
        let workflow = Workflow(step: step)
        let result = try await workflow.run(prompt: "hello world")
        #expect(result.allTexts.joined(separator: "\n") ==
                """
                Agent 2:
                Agent 1:
                hello world
                """)
    }

    @Test
    func testParrallelWorkflow() async throws {
        let agent1 = AIAgent(title: "", model: MockModel(id: 1))
        let agent2 = AIAgent(title: "", model: MockModel(id: 2))
        let step = Workflow.Step.parrallel([.single(agent1), .single(agent2)])
        let workflow = Workflow(step: step)
        let result = try await workflow.run(prompt: "hello world")
        #expect(result.allTexts.joined(separator: "\n") ==
                """
                Agent 1:
                hello world
                Agent 2:
                hello world
                """
                ||
                result.allTexts.joined(separator: "\n") ==
                """
                Agent 2:
                hello world
                Agent 1:
                hello world
                """
        )
    }


    @Test(arguments: [(true, "Agent 1:\nhello world"),
                      (false , "")])
    func testConditionalWorkflow(condition: Bool, output: String) async throws {
        let agent1 = AIAgent(title: "", model: MockModel(id: 1))
        let stepTrue = Workflow.Step.conditional({ result in
            condition
            }, .single(agent1))
        let workflowTrue = Workflow(step: stepTrue)
        let result = try await workflowTrue.run(prompt: "hello world")
        #expect(result.allTexts.joined(separator: "\n") == output)
    }
}
