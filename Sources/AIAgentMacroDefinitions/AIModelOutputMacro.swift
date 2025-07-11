import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

enum AIModelOutputMacroDiagnostic: String, DiagnosticMessage {
    case requiresStructOrEnum = "@AIModelOutput can only be applied to a struct or an enum"

    var message: String { rawValue }
    var diagnosticID: MessageID { MessageID(domain: "SwiftAIAgentMacros", id: "AIModelOutputMacro.\(self)") }
    var severity: DiagnosticSeverity { .error }
}

public struct AIModelOutputMacro: ExtensionMacro {
    public static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingExtensionsOf type: some TypeSyntaxProtocol,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: AIModelOutputMacroDiagnostic.requiresStructOrEnum))
            return []
        }

        guard let jsonSchema = declaration.as(EnumDeclSyntax.self)?.outputModelSchema
                ?? declaration.as(StructDeclSyntax.self)?.outputModelSchema else { return [] }
        let result: DeclSyntax =
            #"""
            """
            \#(raw: jsonSchema.compactJson)
            """
            """#

        let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): AIModelOutput") {
            """
            static var outputSchema: String { \(raw: result) }
            """
        }

        return [extensionDecl]
    }
}
