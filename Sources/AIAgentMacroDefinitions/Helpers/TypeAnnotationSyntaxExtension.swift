import SwiftSyntax

extension TypeAnnotationSyntax {
    var schemaChain: PropertySchemaParsed {
        let typeValue = typeName(type)
        let required = if let _ = type.as(OptionalTypeSyntax.self) {
            false
        } else {
            true
        }
        let itemsTypes = itemsTypes(type)
        return .init(type: typeValue ?? "",
                     itemsType: itemsTypes,
                     required: required)
    }

    private func typeName(_ type: TypeSyntax) -> String? {
        if let idType = type.as(IdentifierTypeSyntax.self) {
            idType.name.text
        } else if let optType = type.as(OptionalTypeSyntax.self) {
            typeName(optType.wrappedType)
        } else if let arrayType = type.as(ArrayTypeSyntax.self) {
            "Array"
        } else if let _ = type.as(DictionaryTypeSyntax.self) {
            "Dictionary"
        } else {
            nil
        }
    }

    private func itemsTypes(_ type: TypeSyntax) -> String? {
        if let optType = type.as(OptionalTypeSyntax.self) {
            itemsTypes(optType.wrappedType)
        } else if let arrayType = type.as(ArrayTypeSyntax.self),
                  let itemTypeValue = typeName(arrayType.element) {
            if itemTypeValue.jsonType == .null {
                #"\(\#(itemTypeValue).outputSchema)"#
            } else {
                "{\"type\":\"\(itemTypeValue.jsonType.rawValue)\"}"
            }
        } else {
            nil
        }
    }
}
