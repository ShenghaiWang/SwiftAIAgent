import SwiftSyntax

extension TypeAnnotationSyntax {
    var schemaChain: PropertySchemaParsed {
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
