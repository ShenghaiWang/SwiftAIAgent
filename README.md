
# SwiftAIAgent

An AI Agent framework in Swift

## The mission

Leverage ‎`Swift` to build AI Agent systems that are both simple and swift.

## Usage

### Auto workflow

```swift
let model = GeminiSDK(model: "gemini-2.5-flash", apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
let autoWorkflow = AutoWorkflow(model: model, goal: "Write an article about history of AI and output it in markdown format")
try await autoWorkflow.run()
```

Let AI model figure out what's the best to do. Only support sequence flow at the moment.

### Mannal workflow

```swift
let gemini = GeminiSDK(model: "gemini-2.5-flash",
                       apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")


let context = AIAgentContext("""
                         The task is to write an essay about the history of AI.
                         A few agents work on this task.
                         """)


let draftAgent = AIAgent(title: "Draft article",
                         model: gemini,
                         context: context,

                         instruction: """
                         You are an expert in writing articles based on your knowledge.
                         """)
let reviewAgent = AIAgent(title: "Review",
                          model: gemini,
                          context: context,
                          instruction: """
                        You are an expert in reviewing articles. Please review and improve the article you are given.
                        """)
let finaliserAgent = AIAgent(title: "Finaliser",
                             model: gemini,
                             context: context,
                             instruction: """
                        You are an expert in finialising articles. Please finalise the article based on the draft and review
                        """)

await finaliserAgent.add(input: draftAgent.id)
let draftStep = Workflow.Step.single(draftAgent)
let reviewStep = Workflow.Step.single(reviewAgent)
let finaliseStep = Workflow.Step.single(finaliserAgent)
let workflow = Workflow(step: .sequence([draftStep, reviewStep, finaliseStep]))

let result = try await workflow.run(prompt: "Let's write this artile")
```

Orchestrate workflow manually. Support sequence, parrallel, condintinal flow types.

## Structured output

Use `@AIModelOutput` macro to generate json schema and feed to LLM model to get structured data.

For example,

```swift
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
```
will generate schema below:

```swift
extension AITask: AIModelOutput {
    static var outputSchema: String {
        """
        {"type":"object","description":"Task that is broken down from a goal","properties":{"name":{"type":"string","description":"A descriptive name of the task"},"details":{"type":"string","description":"The details a task needs to do"},"condition":{"type":"string","description":"The condition to run this step"},"runSubTasksInParallel":{"type":"boolean","description":"Run sub tasks in parralel"},"subTasks":{"type":"array","description":"Sub tasks, an recursive structure to indicate the excute orders of the tasks","items":\(AISubTask.outputSchema)}},"required":["name","details"]}
        """
    }
}
```

## Early stage

The project currently supports basic workflows, but it remains in an early phase. 
Features like tool calling, MCP integration, and other improvements are coming soon. 
If you’d like to join this mission, feel free to reach out.
