import Foundation

public enum HarmCategory: String, Codable {
    case unspecified = "HARM_CATEGORY_UNSPECIFIED"
    case derogatory = "HARM_CATEGORY_DEROGATORY"
    case toxicity = "HARM_CATEGORY_TOXICITY"
    case violence = "HARM_CATEGORY_VIOLENCE"
    case sexual = "HARM_CATEGORY_SEXUAL"
    case medical = "HARM_CATEGORY_MEDICAL"
    case dangerous = "HARM_CATEGORY_DANGEROUS"
    case harassment = "HARM_CATEGORY_HARASSMENT"
    case hateSpeech = "HARM_CATEGORY_HATE_SPEECH"
    case explicit = "HARM_CATEGORY_SEXUALLY_EXPLICIT"
    case dangerousCpntent = "HARM_CATEGORY_DANGEROUS_CONTENT"
    case integrity = "HARM_CATEGORY_CIVIC_INTEGRITY"
}
