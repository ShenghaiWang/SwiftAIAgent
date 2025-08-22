import Testing

@testable import AITools

struct GoogleCustomSearchEngineTests {
    @Test("Test request parameters")
    func requestParameters() {
        let request = GoogleSearch.Request(q: "search")
        #expect(request.parameters == "q=search")

        let request2 = GoogleSearch.Request(q: "search", safe: "off")
        #expect(request2.parameters == "q=search&safe=off")
    }
}
