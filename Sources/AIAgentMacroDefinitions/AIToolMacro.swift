import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

enum AIToolMacroDiagnostic: String, DiagnosticMessage {
    case requiresStructOrEnum = "@AIToolMacro can only be applied to a struct, class, actor or enum"

    var message: String { rawValue }
    var diagnosticID: MessageID { MessageID(domain: "SwiftAIAgentMacros", id: "AIToolMacro.\(self)") }
    var severity: DiagnosticSeverity { .error }
}

public struct AIToolMacro: ExtensionMacro {
    public static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingExtensionsOf type: some TypeSyntaxProtocol,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self)
                || declaration.is(EnumDeclSyntax.self)
                || declaration.is(ActorDeclSyntax.self)
                || declaration.is(ClassDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: AIModelOutputMacroDiagnostic.requiresStructOrEnum))
            return []
        }

        let toolSchemas = declaration
            .memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self)?.toolSchema }

        let result: DeclSyntax =
            #"""
            """
            \#(raw: toolSchemas)
            """
            """#

        let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): AITool") {
            """
            static var toolSchemas: [String] { \(raw: result) }
            """
        }

        return [extensionDecl]
    }
}
