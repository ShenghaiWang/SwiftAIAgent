import Foundation
import Testing
@testable import SwiftAIAgent

struct ToolCallingValueTests {
    @Test
    func testParsing() throws {
        let toolCallingValue = ToolCallingValue(value:
            """
                {"name":"getWeather","args":{"city":"Sydney", "date": { "month":"Jan" }}}
            """)!
        let sydneyEncoded = try JSONEncoder().encode("Sydney")
        #expect(toolCallingValue.name == "getWeather")
        #expect(toolCallingValue.args["city"] == sydneyEncoded)
        #expect(toolCallingValue.args["date"] == Data(#"{"month":"Jan"}"#.utf8))
        #expect(
            [
                """
                {"date":{"month":"Jan"}"city":"Sydney"}
                """,
                """
                {"city":"Sydney""date":{"month":"Jan"}}
                """
            ].contains(toolCallingValue.argsString)
        )
    }
}
