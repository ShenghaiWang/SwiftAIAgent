import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum AIToolMacroDiagnostic: String, DiagnosticMessage {
    case requiresStructOrEnum = "@AIToolMacro can only be applied to a struct, class, actor or enum"

    var message: String { rawValue }
    var diagnosticID: MessageID {
        MessageID(domain: "SwiftAIAgentMacros", id: "AIToolMacro.\(self)")
    }
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
        guard
            declaration.is(StructDeclSyntax.self)
                || declaration.is(EnumDeclSyntax.self)
                || declaration.is(ActorDeclSyntax.self)
                || declaration.is(ClassDeclSyntax.self)
        else {
            context.diagnose(
                Diagnostic(node: node, message: AIModelSchemaMacroDiagnostic.requiresStructOrEnum))
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
        let toolSchemas =
            functions
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
            let returnType =
                function.signature.returnClause?.type.description.trimmingCharacters(
                    in: .whitespacesAndNewlines) ?? "Void"
            let typeCast =
                "(\(paramTypes)) \(function.isAsyncFunction ? "async " : "")\(function.isThrowingFunction ? "throws " : "")-> \(returnType)"
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
                let isOptional = type.hasSuffix("?")
                if isOptional {
                    // Optional type: allow missing data
                    return
                        "let \(label): \(type) = args[\"\(label)\"].flatMap { try? JSONDecoder().decode(\(type.replacingOccurrences(of: "?", with: "")).self, from: $0) }"
                } else {
                    // Non-optional type: require data
                    return
                        "let \(label) = try JSONDecoder().decode(\(type).self, from: args[\"\(label)\"]!)"
                }
            }.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: "\n")
            let paramNames = params.map { $0.firstName.text }.joined(separator: ", ")
            let tryKeyword = function.isThrowingFunction ? "try " : ""
            let throwsKeyword = function.isThrowingFunction ? "throws " : ""
            let awaitKeyword = function.isAsyncFunction ? "await " : ""
            let asyncKeyword = function.isAsyncFunction ? "async " : ""
            let fnType =
                "(\(params.map { $0.type.description.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: ", "))) \(asyncKeyword)\(throwsKeyword)-> \(function.signature.returnClause?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Void")"
            let guardArgs =
                params.isEmpty
                ? ""
                : """
                \(paramCasts)
                """
            let callArgs = params.isEmpty ? "" : paramNames
            return
                """
                case "\(name)":
                guard let fn = methodMap[methodName] as? \(fnType) else { return nil }
                \(guardArgs)
                return \(tryKeyword)\(awaitKeyword)fn(\(callArgs))
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
