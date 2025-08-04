import Foundation

public enum GeminiModality: String, Codable, Sendable {
    case unspecified = "MODALITY_UNSPECIFIED"
    case text = "TEXT"
    case image = "IMAGE"
    case audio = "AUDIO"
}
