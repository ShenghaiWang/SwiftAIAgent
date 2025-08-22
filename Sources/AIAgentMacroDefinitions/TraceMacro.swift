import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum TraceMacroDiagnostic: String, DiagnosticMessage {
    case requiresFunction = "@Traced can only be applied to functions"

    var message: String { rawValue }
    var diagnosticID: MessageID {
        MessageID(domain: "SwiftAIAgentMacros", id: "TraceMacro.\(self)")
    }
    var severity: DiagnosticSeverity { .error }
}

public struct TraceMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: TraceMacroDiagnostic.requiresFunction))
            return []
        }

        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            let trackerExpr = arguments.first(where: { $0.label?.text == "by" })?.expression
        else {
            return []
        }

        let messageExpr: ExprSyntax
        if let customMessageExpr = arguments.first(where: { $0.label?.text == "message" })?
            .expression
        {
            messageExpr = customMessageExpr
        } else {
            messageExpr = ExprSyntax(stringLiteral: "\"\\(#function)\"")
        }

        let logStatement: CodeBlockItemSyntax = "\(trackerExpr).trace(message: \(messageExpr))"
        let originalBody = function.body?.statements ?? []
        return [logStatement] + Array(originalBody)
    }
}
