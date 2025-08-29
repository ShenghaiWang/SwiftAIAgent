import AIAgentMacros

@AIModelSchema
struct RgbColor: Codable, Hashable, Sendable {
    /// The blue component of the color, from 0.0 to 1.0.
    var blue: Float
    /// The green component of the color, from 0.0 to 1.0.
    var green: Float
    /// The red component of the color, from 0.0 to 1.0.
    var red: Float

    /// Creates a new `RgbColor`.
    ///
    /// - Parameters:
    ///   - blue: The blue component of the color, from 0.0 to 1.0.
    ///   - green: The green component of the color, from 0.0 to 1.0.
    ///   - red: The red component of the color, from 0.0 to 1.0.
    init(
        blue: Swift.Float,
        green: Swift.Float,
        red: Swift.Float,
    ) {
        self.blue = blue
        self.green = green
        self.red = red
    }
}
