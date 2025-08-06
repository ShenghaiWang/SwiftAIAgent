import Testing
@testable import GeminiSDK
import Foundation
import AIAgentMacros

/// The location parameter for getWeather function
@AIModelSchema
struct Location {
    /// the name of the city
    let city: String
}

struct GeminiSDKTests {
    @Test
    func testAPICall() async throws {
//        let sdk = GeminiSDK(model: "gemini-2.5-flash",
//                            apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
//        let response = try await sdk.textGeneration(
//            prompt: "What's the weather like today in Sydney?",
//            tools: [.init(functionDeclarations: [.init(name: "getWeather",
//                                                       description: "Find the weather in the specified city",
//                                                       parametersJsonSchema: Location.outputSchema)])])
//        #expect(!response.isEmpty)
    }

    @Test("Parse function call from response")
    func parseFunctioncalls() throws {
        let response = """
            {
              "candidates": [
                {
                  "content": {
                    "parts": [
                      {
                        "functionCall": {
                          "name": "getWeather",
                          "args": {
                            "city": "Sydney"
                          }
                        }
                      },
                      {
                        "functionCall": {
                          "name": "getWeather2",
                          "args": {
                            "city": "Melbourne"
                          }
                        }
                      }            
                    ],
                    "role": "model"
                  },
                  "finishReason": "STOP",
                  "index": 0
                }
              ]
            }
            """
        let data = Data(response.utf8)
        let functionCalls = try data.functionCalls()
        #expect(functionCalls == ["{\"name\":\"getWeather\",\"args\":{\"city\":\"Sydney\"}}",
                                  "{\"name\":\"getWeather2\",\"args\":{\"city\":\"Melbourne\"}}"])
    }

    @Test("Requesting function calls")
    func requestingFunctionCalls() throws {
        let request = GeminiRequest(
            contents: [.init(parts: [.init(text: "")])],
            tools: [.init(functionDeclarations: [.init(name: "getWeather",
                                                       description: "Find the weather in the specified city",
                                                       parametersJsonSchema: Location.outputSchema)])]
        )
        #expect(request.requestingFunctionCalls)
    }
}
