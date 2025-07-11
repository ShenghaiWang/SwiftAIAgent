import SwiftSyntax

extension VariableDeclSyntax {
    var outputModelSchema: PropertySchema? {
        // TODO: Refine it to setter only?
        // TODO: Use propertyType.jsonType.rawValue to chain type defs
        guard bindings.first?.accessorBlock == nil else { return nil }
        guard let shcemaChain = bindings.first?.typeAnnotation?.schemaChain else { return nil }
        let description = leadingTrivia.docLineComment
        let propertyName = bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text ?? ""
        let itemsSchema: String = if let itemsType = shcemaChain.itemsType { ",\"items\": \(itemsType)" } else  { "" }
        let schema =
                      """
                          "\(propertyName)": {
                            "type": "\(shcemaChain.type.jsonType.rawValue)",
                            "description": "\(description)"
                            \(itemsSchema)
                          }
                      """

        return PropertySchema(name: propertyName,
                              schema: schema,
                              required: shcemaChain.required,
                              description: description)
    }
}
