import Foundation

public enum BlockReason: String, Decodable {
    case unspecified = "BLOCK_REASON_UNSPECIFIED"
    case safety = "SAFETY"
    case other = "OTHER"
    case blocklist = "BLOCKLIST"
    case prohibitedContent = "PROHIBITED_CONTENT"
    case imageSafety = "IMAGE_SAFETY"
}
