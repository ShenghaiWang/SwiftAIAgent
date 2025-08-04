import Foundation

public struct Schema: Codable {
    public enum `Type`: String, Codable {
        case unspecified = "TYPE_UNSPECIFIED"
        case string = "STRING"
        case number = "NUMBER"
        case integer = "INTEGER"
        case bollean = "BOOLEAN"
        case array = "ARRAY"
        case object = "OBJECT"
        case null = "NULL"
    }
    let type: Type
    let format: String?
    let title: String?
    let description: String?
    let nullable: Bool?
    let `enum`: [String]?
    let maxItems: Int?
    let minItems: Int?
    let properties: [String: Schema]?
    let required: [String]?
    let miniProperties: Int?
    let maxProperties: Int?
    let minLength: Int?
    let maxLength: Int?
    let pattern: String?
    let example: String?
    let anyOf: [Schema]?
    let propertyOrdering: [String]?
    let `default`: String?
    let items: [Schema]?
    let minimum: Int?
    let maximum: Int?

    public init(type: Type,
         format: String? = nil,
         title: String? = nil,
         description: String? = nil,
         nullable: Bool? = nil,
         `enum`: [String]? = nil,
         maxItems: Int? = nil,
         minItems: Int? = nil,
         properties: [String : Schema]? = nil,
         required: [String]? = nil,
         miniProperties: Int? = nil,
         maxProperties: Int? = nil,
         minLength: Int? = nil,
         maxLength: Int? = nil,
         pattern: String? = nil,
         example: String? = nil,
         anyOf: [Schema]? = nil,
         propertyOrdering: [String]? = nil,
         `default`: String? = nil,
         items: [Schema]? = nil,
         minimum: Int? = nil,
         maximum: Int? = nil
    ) {
        self.type = type
        self.format = format
        self.title = title
        self.description = description
        self.nullable = nullable
        self.enum = `enum`
        self.maxItems = maxItems
        self.minItems = minItems
        self.properties = properties
        self.required = required
        self.miniProperties = miniProperties
        self.maxProperties = maxProperties
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.example = example
        self.anyOf = anyOf
        self.propertyOrdering = propertyOrdering
        self.`default` = `default`
        self.items = items
        self.minimum = minimum
        self.maximum = maximum
    }
}
