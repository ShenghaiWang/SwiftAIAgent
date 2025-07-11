enum JSONType: String {
    case string
    case number
    case object
    case array
    case null
    case boolean
}

extension String {
    var jsonType: JSONType {
        switch self {
        case "String": .string
        case "Bool": .boolean
        case "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64", "Float", "Double", "CGFloat": .number
        case "Dictionary": .object // Not supported yet
        case "Array": .array
        case "Data": .string // Data as base64 string
        case "Date": .string // ISO8601 string
        case "URL": .string
        case "UUID": .string
        default: .null
        }
    }
}
