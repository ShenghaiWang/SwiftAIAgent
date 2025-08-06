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

        let functions = declaration
            .memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            .filter { !$0.modifiers.compactMap(\.name.text).contains("private") }

        let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): AITool") {
            """
            public static var toolSchemas: [String] { \(raw: toolSchemaDecl(for: functions)) }
            
            public var methodMap: [String: Any] { \(raw: methodMap(for: functions)) }
            
            public func call(_ methodName: String, args: [String: Data]) async throws -> Sendable? { \(raw: call(for: functions)) }
            """
        }

        return [extensionDecl]
    }

    private static func toolSchemaDecl(for functions: [FunctionDeclSyntax]) -> DeclSyntax {
        let toolSchemas = functions
            .compactMap { $0.toolSchema }
            .map { name, description, parametersJsonSchema in
                """
                {
                    "name": "\(name)",
                    "description": "\(description)",
                    "parametersJsonSchema": \(parametersJsonSchema)
                }
                """
            }
            .map {
                #"""
                """
                \#($0.compactJson)
                """
                """#
            }.joined(separator: ",\n")

        return
            #"""
            [
            \#(raw: toolSchemas)
            ]
            """#
    }

    private static func methodMap(for functions: [FunctionDeclSyntax]) -> DeclSyntax {
        let entries = functions.map { function in
            let name = function.name.text
            let paramTypes = function.signature.parameterClause.parameters
                .map { param in
                    param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .joined(separator: ", ")
            let returnType = function.signature.returnClause?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Void"
            let typeCast = "(\(paramTypes)) \(function.isThrowingFunction ? "throws " : "")-> \(returnType)"
            return #""\#(name)": self.\#(name) as \#(typeCast)"#
        }
        let dictBody = entries.joined(separator: ",\n")
        return
               #"""
               [
               \#(raw: dictBody)
               ]
               """#
    }

    private static func call(for functions: [FunctionDeclSyntax]) -> DeclSyntax {
        let cases = functions.map { function in
            let name = function.name.text
            let params = function.signature.parameterClause.parameters
            let paramCasts = params.enumerated().map { idx, param in
                let type = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                let label = param.firstName.text
                return "let data = args[\"\(label)\"], let \(label) = try? JSONDecoder().decode(\(type).self, from: data)"
            }.joined(separator: ",\n")
            let paramNames = params.map { $0.firstName.text }.joined(separator: ", ")
            let fnType = "(\(params.map { $0.type.description.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: ", "))) \(function.isThrowingFunction ? "throws " : "")-> \(function.signature.returnClause?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Void")"
            let guardArgs = params.isEmpty ? "" :
                """
                guard \(paramCasts) else { return nil }
                """
            let callArgs = params.isEmpty ? "" : paramNames
            let tryKeyword = function.isThrowingFunction ? "try " : ""
            return
                """
                case "\(name)":
                guard let fn = methodMap[methodName] as? \(fnType) else { return nil }
                \(guardArgs)
                return \(tryKeyword)fn(\(callArgs))
                """
        }.joined(separator: "\n")

        return
            #"""
            switch methodName {
            \#(raw: cases)
            default:
                return nil
            }
            """#
    }
}
