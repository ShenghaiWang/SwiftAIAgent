public protocol AIModelOutput: Decodable, Sendable {
    static var outputSchema: String { get }
}

public protocol Tracker {
    func trace(message: String)
}

/// A macro that produces the json schema for the types it attaches to
@attached(extension, conformances: AIModelOutput, names: named(outputSchema))
public macro AIModelOutput() = #externalMacro(module: "AIAgentMacroDefinitions", type: "AIModelOutputMacro")

/// A macro that trace the json schema for the types it attaches to
@attached(body)
public macro Traced(by tracker: Tracker, message: String = "") = #externalMacro(module: "AIAgentMacroDefinitions", type: "TraceMacro")
