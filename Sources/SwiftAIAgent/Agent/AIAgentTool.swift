import AIAgentMacros

public typealias AIAgentTool = AITool

extension Array where Element == AIAgentTool {
    var toolDefinitions: [String] {
        flatMap {
            type(of: $0).toolSchemas
        }
    }
}
