import Foundation

public protocol AIModelOutput: Decodable, Sendable {
    static var outputSchema: String { get }
}

public protocol AITool: Decodable, Sendable {
    static var toolSchemas: [String] { get }
    var methodMap: [String: Any] { get }
    func call(_ methodName: String, args: [String: Data]) async throws -> Sendable?
}

public protocol Tracker {
    func trace(message: String)
}

/// A macro that produces the json schema for the types it attaches to
@attached(extension, conformances: AIModelOutput, names: named(outputSchema))
public macro AIModelOutput() = #externalMacro(module: "AIAgentMacroDefinitions", type: "AIModelOutputMacro")

/// A macro that produces the tool schema for the types it attaches to
@attached(extension, conformances: AITool, names: named(toolSchemas), named(methodMap), named(call))
public macro AITool() = #externalMacro(module: "AIAgentMacroDefinitions", type: "AIToolMacro")

/// A macro helps to trace call stacks
@attached(body)
public macro Traced(by tracker: Tracker, message: String = "") = #externalMacro(module: "AIAgentMacroDefinitions", type: "TraceMacro")
