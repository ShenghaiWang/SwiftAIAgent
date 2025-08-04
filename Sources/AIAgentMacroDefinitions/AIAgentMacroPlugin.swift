import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AIAgentMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AIModelOutputMacro.self,
        TraceMacro.self,
        AIToolMacro.self,
    ]
}
