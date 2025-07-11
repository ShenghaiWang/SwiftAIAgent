import Foundation

extension String {
    var compactJson: String {
        removeWhitespaceOutsideQuotes(from: self)
    }

    func removeWhitespaceOutsideQuotes(from json: String) -> String {
        var result = ""
        var inQuotes = false
        var prevChar: Character? = nil

        for char in json {
            if char == "\"" && prevChar != "\\" {
                inQuotes.toggle()
                result.append(char)
            } else if !inQuotes && char.isWhitespace {
                // Skip whitespace outside quotes
            } else {
                result.append(char)
            }
            prevChar = char
        }
        return result
    }
}
