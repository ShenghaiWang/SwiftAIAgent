import SwiftSyntax

extension TriviaPiece {
    var docLineComment: String {
        guard case let .docLineComment(text) = self else { return "" }
        return text.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Array where Element == TriviaPiece {
    var docLineComments: String {
        map(\.docLineComment).filter { !$0.isEmpty }.joined(separator: ";")
    }
}

extension Trivia {
    var docLineComment: String {
        pieces.docLineComments
    }
}
