import SwiftSyntax

extension TypeAnnotationSyntax {
    var schemaChain: PropertySchemaParsed {
        let required = if let _ = type.as(OptionalTypeSyntax.self) {
            false
        } else {
            true
        }
        return .init(type: type.typeName ?? "",
                     itemsType: type.typeSchema,
                     required: required)
    }
}
