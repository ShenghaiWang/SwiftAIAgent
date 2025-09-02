import Foundation
import SwiftSyntax

typealias ParameterSchema = PropertySchema

extension FunctionParameterSyntax {
    func parameterSchema(description: String) -> ParameterSchema? {
        guard let schemaChain else { return nil }
        let itemsSchema: String =
            if let itemsType = schemaChain.itemsType { ",\"items\": \(itemsType)" } else { "" }

        let schema =
            if ![JSONType.object, .null].contains(schemaChain.type.jsonType) {
                """
                    "\(firstName.text)": {
                        "type": "\(schemaChain.type.jsonType.rawValue)",
                        "description": "\(description)"
                        \(itemsSchema)
                    }
                """
            } else {
                #"""
                    "\#(firstName.text)":\(\#(schemaChain.type).outputSchema)
                """#
            }

        return PropertySchema(
            name: firstName.text,
            schema: schema,
            required: schemaChain.required,
            description: ""
        )
    }

    var schemaChain: PropertySchemaParsed? {
        let required =
            if type.as(OptionalTypeSyntax.self) != nil {
                false
            } else {
                true
            }
        return .init(
            type: type.typeName ?? "",
            itemsType: type.typeSchema,
            required: required
        )
    }
}
