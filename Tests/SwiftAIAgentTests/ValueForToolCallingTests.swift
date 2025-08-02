import Foundation
import Testing
@testable import SwiftAIAgent

struct SwiftUIChartsTests {
    @Test
    func testParsing() throws {
        let valueForToolCalling = ValueForToolCalling(value:
            """
                {"name":"getWeather","args":{"city":"Sydney", "date": { "month":"Jan", "day": "1" }}}
            """)!
        let sydneyEncoded = try JSONEncoder().encode("Sydney")
        #expect(valueForToolCalling.name == "getWeather")
        #expect(valueForToolCalling.args["city"] == sydneyEncoded)
        #expect(valueForToolCalling.args["date"] == Data(#"{"month":"Jan","day":"1"}"#.utf8))
    }
}
