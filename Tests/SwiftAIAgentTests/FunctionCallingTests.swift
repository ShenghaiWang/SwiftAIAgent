import Testing

@testable import GeminiSDK
@testable import SwiftAIAgent

@Suite("Testing function calling")
struct FuncationCallingTests {
    @Test("Function declaration from string")
    func functionDeclarationFromString() {
        let toolSchema =
            """
            {"name":"getWeather","description":"Get weather of the city","parametersJsonSchema":{"type":"object","required":["city","date"],"properties":{"city":{"type":"array","description":"The city","items":{"type":"string"}},"date":{"type":"string","description":"The date"}}}}
            """
        let functionDecl = toolSchema.functionDeclaration!
        #expect(functionDecl.name == "getWeather")
        #expect(functionDecl.description == "Get weather of the city")
        #expect(
            functionDecl.parametersJsonSchema == """
                {"properties":{"city":{"description":"The city","items":{"type":"string"},"type":"array"},"date":{"description":"The date","type":"string"}},"required":["city","date"],"type":"object"}
                """
        )
    }
}
