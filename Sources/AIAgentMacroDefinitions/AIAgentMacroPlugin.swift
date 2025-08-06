import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AIAgentMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AIModelSchemaMacro.self,
        TraceMacro.self,
        AIToolMacro.self,
    ]
}
