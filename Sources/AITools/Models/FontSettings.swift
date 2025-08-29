import AIAgentMacros

@AIModelSchema
struct FontSettings: Codable, Sendable {
    /// fontFamily: the font that applies to the text
    let fontFamily: String?
    // font size
    let fontSize: Double?
    /// fontWeight: The weight of the font. This field can have any value that's a multiple of `100` between `100` and `900`, inclusive.
    let fontWeight: Int32?
    /// bold: if set text in blod style, 1 for `bold` style and 0 for otherwise
    let bold: Int?
    /// italic: if set text in italic style, 1 for `italic` style and 0 for otherwise
    let italic: Int?
    /// strikethrough: if set text in strikethrough style, 1 for `strikethrough` style and 0 for otherwise
    let strikethrough: Int?
    /// underline: if set text in underline style, 1 for `underline` style and 0 for otherwise
    let underline: Int?
}
