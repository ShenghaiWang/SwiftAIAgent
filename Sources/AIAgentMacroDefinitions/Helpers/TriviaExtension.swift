import SwiftSyntax

extension TriviaPiece {
    var docLineComment: String? {
        guard case let .docLineComment(text) = self else { return nil }
        return text.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Array where Element == TriviaPiece {
    var docLineComments: [String] {
        compactMap(\.docLineComment)
    }
}

extension Trivia {
    var docLineComment: String {
        docLineComments.filter { !$0.isEmpty }.joined(separator: ";")
    }

    var docLineComments: [String] {
        pieces.docLineComments
    }
}
