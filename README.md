
# SwiftAIAgent

An AI Agent framework in Swift

## The mission

Leverage ‎`Swift` to build AI Agent systems that are both simple and swift.

## Usage

There are demos in `main.swift` in `Client` target. You can run them directly to understand how it works.
Please note, need to configure the environment varibales `GEMINI_API_KEY`, `GitHubToken`(for GitHub MCP Server), `cx` & `key` (for Google search tool).

```swift
// MCP connection example
try await MCPConnection().run()

// Workflow example
try await AgentWorkflow.manual.run()
try await AgentWorkflow.automatic.run()

// Tool calling example
try await ToolCalling.run()

// Gemini Image Generation
try await GminiImageGeneration.run()

// Gemini Speech Generation
try await GminiSpeechGeneration.run()

// Google search tool
try await GoogleSearchTool.run()

// Tool & MCP
try await GoogleSearchTool.run()
```

### Auto workflow

```swift
let model = GeminiSDK(model: "gemini-2.5-flash", apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
let autoWorkflow = AutoWorkflow(model: model, goal: "Write an article about history of AI and output it in markdown format")
try await autoWorkflow.run()
```

Let AI model figure out what's the best to do. Only support sequence flow at the moment. It might ask clarification question depending on your goal. If you think you want it run without futher questions, just input `run without more questions` to kick off the workflow.

#### What this can do depends on the tools/mcp servers we configure, for example:

- with `GoogleSearch`, `Fetch`, `FileIO` tools, it can achive goals like: 

```
Write a summary of developments in computer science over the past 12 months, 
using information from the top 10 websites in the search results and save it in a markdown file.
```
The result of my last run of this goal was [computer_science_developments.md](./Examples/computer_science_developments.md)

- with `GitHub MCP Server`, we can ask it to perform all the tasks this mcp server provides like:
```
Get all the tags of https://github.com/ShenghaiWang/SwiftAIAgent.git
```
The result of my last run of this goal was `"The following tags were found for the repository: v0.0.4, v0.0.3, v0.0.2, v0.0.1")`

### Mannal workflow

```swift
let draftAgent = AIAgent(title: "Draft article",
                         model: gemini,
                         instruction: "Please draft an article about the history of AI")
let reviewAgent = AIAgent(title: "Review",
                          model: gemini,
                          instruction: "Please review the draft and give your feedback.")
let finaliserAgent = AIAgent(title: "Finaliser",
                             model: gemini,
                             instruction: "Please finalise this article based on the draft and review")
await finaliserAgent.add(input: draftAgent.id)
let draftStep = Workflow.Step.single(draftAgent)
let reviewStep = Workflow.Step.single(reviewAgent)
let finaliseStep = Workflow.Step.single(finaliserAgent)
let workflow = Workflow(step: .sequence([draftStep, reviewStep, finaliseStep]))
let result = try await workflow.run(prompt: "Let's write this artile")
```

Orchestrate workflow manually. Support sequence, parrallel, condintinal flow types.

## Structured output

Use `@AIModelSchema` macro to generate json schema and feed to LLM model to get structured data.

For example,

```swift
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
```
will generate schema below:

```swift
extension AITask: AIModelSchema {
    static var outputSchema: String {
        """
        {"type":"object","description":"Task that is broken down from a goal","properties":{"name":{"type":"string","description":"A descriptive name of the task"},"details":{"type":"string","description":"The details a task needs to do"},"condition":{"type":"string","description":"The condition to run this step"},"runSubTasksInParallel":{"type":"boolean","description":"Run sub tasks in parralel"},"subTasks":{"type":"array","description":"Sub tasks, an recursive structure to indicate the excute orders of the tasks","items":\(AISubTask.outputSchema)}},"required":["name","details"]}
        """
    }
}
```

## Function/Tool Calling

### Define tools

Once mark a type using `@AITool`, all the functions of that type that are not private will be made availbe to LLM. 

```swift
@AITool
struct ToolStruct {
    /// Get weather of the city
    /// - Parameters:
    ///  - city: The city
    /// - Returns: Weather of the city
    func getWeather(city: String) -> String {
        "It's raining in Sydney"
    }
}
```

### Configure tool to agent and run it by agent automatically if needed.

```swift
let gemini = GeminiSDK(model: "gemini-2.5-flash",
                       apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
let context = AIAgentContext("Get weather")
let agent = AIAgent(title: "Weahter Agent",
                    model: gemini,
                    tools: [ToolStruct()],
                    context: context,
                    instruction: "")
let result = try await agent.run(prompt: "Get weather for Sydney")
print(result)
```
## Use MCP Servers

```swift
let gemini = GeminiSDK(model: geminiModel,
                       apiKey: geminiAPIKey)
let gitHubURL = URL(string: "https://api.githubcopilot.com/mcp/")!
let testAgent = try await AIAgent(title: "Draft article",
                                   model: gemini,
                                   mcpServers: [.http(url: gitHubURL, token: gitHubToken)],
                                   instruction: "Get all the tags of this repo https://github.com/ShenghaiWang/SwiftLlama")
let step = Workflow.Step.single(testAgent)
let workflow = Workflow(step: step)
let result = try await workflow.run(prompt: "start")
```

## Early stage

The project currently supports basic workflows, but it remains in an early phase. 
Features like tool calling, MCP integration, and other improvements are coming soon. 
If you’d like to join this mission, feel free to reach out.

## Watch a sample workflow run

[![Watch the video](https://img.youtube.com/vi/te_CZrwrphs/0.jpg)](https://www.youtube.com/watch?v=te_CZrwrphs)
