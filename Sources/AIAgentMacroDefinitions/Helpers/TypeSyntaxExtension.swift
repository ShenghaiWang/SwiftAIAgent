import Foundation
import SwiftSyntax

extension TypeSyntax {
    var typeName: String? {
        if let idType = self.as(IdentifierTypeSyntax.self) {
            idType.name.text
        } else if let optType = self.as(OptionalTypeSyntax.self) {
            optType.wrappedType.typeName
        } else if self.as(ArrayTypeSyntax.self) != nil {
            "Array"
        } else if self.as(DictionaryTypeSyntax.self) != nil {
            "Dictionary"
        } else {
            nil
        }
    }

    var typeSchema: String? {
        if let optType = self.as(OptionalTypeSyntax.self) {
            optType.wrappedType.typeSchema
        } else if let arrayType = self.as(ArrayTypeSyntax.self),
            let itemTypeValue = arrayType.element.typeName
        {
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
