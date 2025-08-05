import Foundation

public enum HarmProbability: String, Decodable {
    case unspecified = "HARM_PROBABILITY_UNSPECIFIED"
    case negligible = "NEGLIGIBLE"
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
}
