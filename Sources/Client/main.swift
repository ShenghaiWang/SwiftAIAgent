import Foundation
import AIAgentMacros
import GeminiSDK
import SwiftAIAgent
import Logging
import MCP
import System

LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = .debug
    return handler
}

enum AgentWorkflow {
    case manaul
    case automatic

    func run() async throws {
        switch self {
        case .manaul:
            try await runManulFlow()
        case .automatic:
            try await ruanAutomaticFlow()
        }
    }

    struct AutoWorkflow {
        let model: AIAgentModel
        let managerAgent: AIAgent
        let goalManager: GoalManager

        init(model: AIAgentModel, goal: String) {
            self.model = model
            self.managerAgent = AIAgent(title: "Manager", model: model)
            self.goalManager = GoalManager(goal: goal, aiagent: managerAgent)
        }


        func run() async throws {
            do {
                let result = try await goalManager.run()
                print(result)
            } catch {
                if case let GoalManager.Error.needClarification(questions) = error {
                    print(questions
                        .enumerated()
                        .map { "\($0 + 1): \($1))" }
                        .joined(separator: "\n"))
                    let clarifications = readLine()
                    await goalManager.set(clarifications: [clarifications ?? ""])
                    try await run()
                } else {
                    print(error)
                }
            }
        }
    }

    private func runManulFlow() async throws {
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
        print(result.output)
    }

    private func ruanAutomaticFlow() async throws {
        let model = GeminiSDK(model: "gemini-2.5-flash", apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
        let autoWorkflow = AutoWorkflow(model: model, goal: "Write an article about history of AI and output it in markdown format")
        try await autoWorkflow.run()
    }
}


enum MCPConnection {
    case mcpxcodebuild
    case github

    var gitHubToken: String {
        ProcessInfo.processInfo.environment["GitHubToken"] ?? ""
    }

    var headers: [String: String] {
        ["Authorization": "Bearer \(gitHubToken)"]
    }

    func connect() async throws {
        switch self {
        case .mcpxcodebuild:
            try await connectToLocalMCPServer()
        case .github:
            try await connectToGitHub()
        }
    }

    private func connectToGitHub() async throws {
        let transport = HTTPClientTransport(
            endpoint: URL(string: "https://api.githubcopilot.com/mcp/")!,
            headers: headers,
            streaming: true // Enable Server-Sent Events for real-time updates if supported
        )
        let client = Client(name: "SwiftAIAgent", version: "1.0.0")
        let result = try await client.connect(transport: transport)

        // Check server capabilities
        if result.capabilities.tools != nil {
            // Server supports tools (implicitly including tool calling if the 'tools' capability object is present)
        }
        let tools = try await client.listTools()
        print("Available tools: \(tools.tools.map { $0.name }.joined(separator: ", "))")
    }

    private func connectToLocalMCPServer() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "uvx") // Make sure uvx is available
        process.arguments = ["mcpxcodebuild"]
        
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        
        try process.run()
        let transport = StdioTransport(
            input: FileDescriptor(rawValue: outputPipe.fileHandleForReading.fileDescriptor),
            output: FileDescriptor(rawValue: inputPipe.fileHandleForWriting.fileDescriptor),
            logger: logger
        )
        let client = Client(name: "SwiftAIAgent", version: "1.0.0")
        let result = try await client.connect(transport: transport)

        // Check server capabilities
        if result.capabilities.tools != nil {
            // Server supports tools (implicitly including tool calling if the 'tools' capability object is present)
        }
        let tools = try await client.listTools()
        print("Available tools: \(tools.tools.map { $0.name }.joined(separator: ", "))")
    }
}

//try await MCPConnection.github.connect()
//try await MCPConnection.mcpxcodebuild.connect()
//
//try await AgentWorkflow.manaul.run()
try await AgentWorkflow.automatic.run()
