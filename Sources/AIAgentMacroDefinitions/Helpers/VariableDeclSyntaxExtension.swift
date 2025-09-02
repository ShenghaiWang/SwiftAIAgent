import SwiftSyntax

extension VariableDeclSyntax {
    var outputModelSchema: PropertySchema? {
        // TODO: Refine it to setter only?
        guard bindings.first?.accessorBlock == nil else { return nil }
        guard let schemaChain = bindings.first?.typeAnnotation?.schemaChain else { return nil }
        let description = leadingTrivia.docLineComment
        let propertyName =
            bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text ?? ""
        let itemsSchema: String =
            if let itemsType = schemaChain.itemsType { ",\"items\": \(itemsType)" } else { "" }
        let schema: String =
            if ![JSONType.object, .null].contains(schemaChain.type.jsonType) {
                """
                    "\(propertyName)": {
                        "type": "\(schemaChain.type.jsonType.rawValue)",
                        "description": "\(description)"
                        \(itemsSchema)
                    }
                """
            } else {
                #"""
                    "\#(propertyName)":\(\#(schemaChain.type).outputSchema)
                """#
            }

        return PropertySchema(
            name: propertyName,
            schema: schema,
            required: schemaChain.required,
            description: description
        )
    }
}
