import Foundation
import SwiftSyntax

extension EnumDeclSyntax {
    var outputModelSchema: String {
        // TODO: add support for associated values
        let description = leadingTrivia.docLineComment
        let casesSchemas = memberBlock.members.compactMap { member in
            member.decl.as(EnumCaseDeclSyntax.self)?.outputModelSchema
        }
        let casesDescription = casesSchemas.compactMap(\.description).joined(separator: ", ")
        let descriptionSchema = "\(description): \(casesDescription)"
        let schema = casesSchemas.map(\.schema).joined(separator: ",")
        return
            """
            {
                "\(name)" : {
                    "description": "\(descriptionSchema)",
                    "enum": [
                        \(schema)
                    ]
                }
            }
            """
    }
}
