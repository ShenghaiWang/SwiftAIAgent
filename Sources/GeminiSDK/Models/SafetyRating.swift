import Foundation

public struct SafetyRating: Decodable {
    let category: HarmCategory
    let probability: HarmProbability
    let blocked: Bool
}
