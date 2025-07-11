import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AIAgentMacroDefsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AIModelOutputMacro.self,
        TraceMacro.self,
    ]
}
