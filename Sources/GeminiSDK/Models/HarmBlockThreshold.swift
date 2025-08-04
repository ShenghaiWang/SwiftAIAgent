import Foundation

public enum HarmBlockThreshold: String, Codable {
    case unspecified = "HARM_BLOCK_THRESHOLD_UNSPECIFIED"
    case low = "BLOCK_LOW_AND_ABOVE"
    case medium = "BLOCK_MEDIUM_AND_ABOVE"
    case high = "BLOCK_ONLY_HIGH"
    case none = "BLOCK_NONE"
    case off = "OFF"
}
