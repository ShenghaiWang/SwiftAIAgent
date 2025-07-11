import Foundation
import SwiftSyntax

extension StructDeclSyntax {
    var outputModelSchema: String {
        let description = leadingTrivia.docLineComment
        let propertySchemas = memberBlock.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)?.outputModelSchema
        }
        let properties = propertySchemas.map(\.schema).joined(separator: ",\n")
        let requiredProperties = propertySchemas.filter(\.required)
            .map { "\"\($0.name)\"" }.joined(separator: ",")
        return
            """
            {
                "type": "object",
                "description": "\(description)",
                "properties": {
                    \(properties)
                },
                "required": [\(requiredProperties)]
            }
            """
    }
}
