import Foundation
import SwiftSyntax

extension TypeSyntax {
    var typeName: String? {
        if let idType = self.as(IdentifierTypeSyntax.self) {
            idType.name.text
        } else if let optType = self.as(OptionalTypeSyntax.self) {
            optType.wrappedType.typeName
        } else if let _ = self.as(ArrayTypeSyntax.self) {
            "Array"
        } else if let _ = self.as(DictionaryTypeSyntax.self) {
            "Dictionary"
        } else {
            nil
        }
    }

    var typeSchema: String? {
        if let optType = self.as(OptionalTypeSyntax.self) {
            optType.wrappedType.typeSchema
        } else if let arrayType = self.as(ArrayTypeSyntax.self),
                  let itemTypeValue = arrayType.element.typeName {
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
