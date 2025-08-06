import Foundation
import SwiftSyntax

extension FunctionDeclSyntax {
    private func parseParameter(from line: String, prefixToRemove: String) -> (name: String, description: String)? {
        let paramLine = line.dropFirst(prefixToRemove.count).trimmingCharacters(in: .whitespaces)
        if let colonIndex = paramLine.firstIndex(of: ":") {
            let name = paramLine[..<colonIndex].trimmingCharacters(in: .whitespaces)
            let desc = paramLine[paramLine.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
            return (name: String(name), description: desc)
        }
        return nil
    }
    
    var parsedDoc: (description: String?, parameters: [String: String], returns: String?) {
        var description: String?
        var parameters: [String: String] = [:]
        var returns: String?
        var inParametersSection = false

        for line in leadingTrivia.docLineComments {
            if line.hasPrefix("- Parameter") && !line.hasPrefix("- Parameters:") {
                inParametersSection = false
                if let (name, description) = parseParameter(from: line, prefixToRemove: "- Parameter") {
                    parameters[name] = description
                }
            } else if line.hasPrefix("- Parameters:") {
                inParametersSection = true
            } else if line.hasPrefix("- Returns:") {
                inParametersSection = false
                returns = line.dropFirst("- Returns:".count).trimmingCharacters(in: .whitespaces)
            } else if description == nil && !line.isEmpty && !line.hasPrefix("-") {
                inParametersSection = false
                description = line
            } else if line.hasPrefix("-") && inParametersSection {
                if let (name, description) = parseParameter(from: line, prefixToRemove: "_") {
                    parameters[name] = description
                }
            }
        }
        return (description, parameters, returns)
    }

    var toolSchema: (name: String, description: String, parametersJsonSchema: String)? {
        let parsedDoc = parsedDoc
        let parameters = signature.parameterClause.parameters
            .compactMap {
                $0.parameterSchema(description: parsedDoc.parameters[$0.firstName.text] ?? "")
            }
        let requiredParameters = parameters.filter(\.required).map({ "\"\($0.name)\"" }).joined(separator: ",")
        return (
            name: name.text,
            description: parsedDoc.description ?? "",
            parametersJsonSchema:
                """
                {
                    "type": "object",
                    "required": [\(requiredParameters)],
                    "properties": {
                        \(parameters.compactMap(\.schema).joined(separator: ","))
                    }
                }
                """
        )
    }

    var isThrowingFunction: Bool {
        signature.effectSpecifiers?.throwsClause != nil
    }

    var isAsyncFunction: Bool {
        signature.effectSpecifiers?.asyncSpecifier != nil
    }
}
