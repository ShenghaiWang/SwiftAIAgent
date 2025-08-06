import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing
@testable import AIAgentMacroDefinitions
import SwiftParser

struct AIToolMacroTests {
    @Test("Tool Macro Test")
    func toolMacroTest() {
        let source: SourceFileSyntax =
                        """
                        @AITool
                        struct ToolStruct {
                            /// Get weather of the city
                            /// - Parameters:
                            ///  - city: The city
                            /// - Returns: Weather of the city
                            func getWeather(city: String) throws -> Weather {
                            }
                        }
                        """
        let transformedSF = source.expand(macros: ["AITool": AIToolMacro.self]) { _ in
            BasicMacroExpansionContext(sourceFiles: [source: file])
        }
        let expectedDescription =
                        #"""
                        
                        struct ToolStruct {
                            /// Get weather of the city
                            /// - Parameters:
                            ///  - city: The city
                            /// - Returns: Weather of the city
                            func getWeather(city: String) throws -> Weather {
                            }
                        }

                        extension ToolStruct: AITool {
                            public static var toolSchemas: [String] {
                                [
                                    """
                                    {"name":"getWeather","description":"Get weather of the city","parametersJsonSchema":{"type":"object","required":["city"],"properties":{"city":{"type":"string","description":"The city"}}}}
                                    """
                                ]
                            }

                            var methodMap: [String: Any] {
                                [
                                    "getWeather": self.getWeather as (String) throws -> Weather
                                ]
                            }

                            public func call(_ methodName: String, args: [String: Data]) async throws -> Sendable? {
                                switch methodName {
                                case "getWeather":
                                    guard let fn = methodMap[methodName] as? (String) throws -> Weather else {
                                        return nil
                                    }
                                    guard let data = args["city"], let city = try? JSONDecoder().decode(String.self, from: data) else {
                                        return nil
                                    }
                                    return try fn(city)
                                default:
                                    return nil
                                }
                            }
                        }
                        """#
        #expect(transformedSF.description == expectedDescription)
    }

    @Test("Test parsing Swift Docc")
    func testParsingSwiftDocc() {
        let doccString =
            """
            /// Get weather of the city
            /// - Parameters:
            ///  - city: The city
            ///  - date: The date
            /// - Returns: Weather of the city
            func getWeather(city: String, date: Date) -> Weather {
            }
            """
        let sourceFile = Parser.parse(source: doccString)
        let parsedDoc = sourceFile.statements
            .compactMap { $0.item.as(FunctionDeclSyntax.self) }
            .first!.parsedDoc
        #expect(parsedDoc.description == "Get weather of the city")
        #expect(parsedDoc.returns == "Weather of the city")
        #expect(parsedDoc.parameters == ["city": "The city", "date": "The date"])
    }

    @Test("Test parsing Swift Docc")
    func testParsingSwiftDoccFormat2() {
        let doccString =
            """
            /// Get weather of the city
            /// - Parameter city: The city
            /// - Parameter date: The date
            /// - Returns: Weather of the city
            func getWeather(city: String) -> Weather {
            }
            """
        let sourceFile = Parser.parse(source: doccString)
        let parsedDoc = sourceFile.statements
            .compactMap { $0.item.as(FunctionDeclSyntax.self) }
            .first!.parsedDoc
        #expect(parsedDoc.description == "Get weather of the city")
        #expect(parsedDoc.returns == "Weather of the city")
        #expect(parsedDoc.parameters == ["city": "The city", "date": "The date"])
    }

    @Test("Test parsing func parameters")
    func testParsingFuncParameter() {
        let doccString =
            """
            /// Get weather of the city
            /// - Parameter city: The city
            /// - Parameter date: The date
            /// - Returns: Weather of the city
            func getWeather(city: [String], date: Date) -> Weather {
            }
            """
        let sourceFile = Parser.parse(source: doccString)
        let funcDecl = sourceFile.statements
            .compactMap { $0.item.as(FunctionDeclSyntax.self) }
            .first!
        let toolSchema = funcDecl.toolSchema
        #expect(toolSchema?.name == "getWeather")
        #expect(toolSchema?.description == "Get weather of the city")
        #expect(toolSchema?.parametersJsonSchema.compactJson ==
            """
            {"type":"object","required":["city","date"],"properties":{"city":{"type":"array","description":"The city","items":{"type":"string"}},"date":{"type":"string","description":"The date"}}}
            """)
    }

    @Test("Test parsing func parameters with Customised type")
    func testParsingFuncParameterOfCustomisedType() {
        let doccString =
            """
            /// Get weather of the date
            /// - Parameter date: The date
            /// - Returns: Weather of the date
            func getWeather(date: WeatherDate) -> Weather {
            }
            """
        let sourceFile = Parser.parse(source: doccString)
        let funcDecl = sourceFile.statements
            .compactMap { $0.item.as(FunctionDeclSyntax.self) }
            .first!
        let toolSchema = funcDecl.toolSchema
        #expect(toolSchema?.name == "getWeather")
        #expect(toolSchema?.description == "Get weather of the date")
        #expect(toolSchema?.parametersJsonSchema.compactJson ==
            #"""
            {"type":"object","required":["date"],"properties":{"date":\(WeatherDate.outputSchema)}}
            """#)
    }
}
