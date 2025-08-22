import Foundation

struct PropertySchema {
    let name: String
    let schema: String
    let required: Bool
    let description: String?
}

struct PropertySchemaParsed {
    let type: String
    let itemsType: String?
    let required: Bool
}
