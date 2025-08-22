import Foundation

// Helper to encode Any as JSON
struct JSONAny: Encodable {
    let value: Any

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as [String: Any]:
            try container.encode(
                Dictionary(uniqueKeysWithValues: v.map { ($0, JSONAny(value: $1)) }))
        case let v as [Any]:
            try container.encode(v.map { JSONAny(value: $0) })
        case let v as String:
            try container.encode(v)
        case let v as Int:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as Bool:
            try container.encode(v)
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid JSON value"
                )
            )
        }
    }
}
