import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

enum AIModelSchemaMacroDiagnostic: String, DiagnosticMessage {
    case requiresStructOrEnum = "@AIModelSchema can only be applied to a struct or an enum"

    var message: String { rawValue }
    var diagnosticID: MessageID { MessageID(domain: "SwiftAIAgentMacros", id: "AIModelSchemaMacro.\(self)") }
    var severity: DiagnosticSeverity { .error }
}

public struct AIModelSchemaMacro: ExtensionMacro {
    public static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingExtensionsOf type: some TypeSyntaxProtocol,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: AIModelSchemaMacroDiagnostic.requiresStructOrEnum))
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
        let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): AIModelSchema") {
            """
            \(declaration.modifiers)static var outputSchema: String { \(raw: result) }
            """
        }

        return [extensionDecl]
    }
}
