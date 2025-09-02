import Foundation
import SwiftSyntax

extension EnumCaseDeclSyntax {
    var outputModelSchema: EnumCaseSchema {
        let identifier = elements.first?.name.text ?? ""
        let description = leadingTrivia.docLineComment
        return .init(
            name: identifier,
            schema: "\"\(identifier)\"",
            description: description
        )
    }
}
