import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing
import AIAgentMacroDefinitions

struct AIModelOutputTests {
    @Test
    func testEnumSchema() {
        let source: SourceFileSyntax =
                        """
                        /// Gender
                        @AIModelOutput
                        enum Gender: String, Codable {
                            /// Gender - male
                            case male
                            /// Gender - female
                            case female
                        }
                        """
        let transformedSF = source.expand(macros: ["AIModelOutput": AIModelOutputMacro.self]) { _ in
            BasicMacroExpansionContext(sourceFiles: [source: file])
        }
        let expectedDescription =
                        #"""
                        /// Gender
                        enum Gender: String, Codable {
                            /// Gender - male
                            case male
                            /// Gender - female
                            case female
                        }
                        
                        extension Gender: AIModelOutput {
                            static var outputSchema: String {
                                """
                                {"Gender":{"description":"Gender: Gender - male, Gender - female","enum":["male","female"]}}
                                """
                            }
                        }
                        """#
        #expect(transformedSF.description == expectedDescription)
    }

    @Test
    func testStructSchema() {
        let source: SourceFileSyntax =
                        """
                        /// Person
                        @AIModelOutput
                        struct Person: Codable {
                            /// Name: first name + last name
                            let name: String
                            /// Age
                            let age: Int?
                            var firstName: String {
                                ""
                            }
                        }
                        """
        let transformedSF = source.expand(macros: ["AIModelOutput": AIModelOutputMacro.self]) { _ in
            BasicMacroExpansionContext(sourceFiles: [source: file])
        }
        let expectedDescription =
                        #"""
                        /// Person
                        struct Person: Codable {
                            /// Name: first name + last name
                            let name: String
                            /// Age
                            let age: Int?
                            var firstName: String {
                                ""
                            }
                        }
                        
                        extension Person: AIModelOutput {
                            static var outputSchema: String {
                                """
                                {"type":"object","description":"Person","properties":{"name":{"type":"string","description":"Name: first name + last name"},"age":{"type":"number","description":"Age"}},"required":["name"]}
                                """
                            }
                        }
                        """#
        #expect(transformedSF.description == expectedDescription)
    }

    @Test
    func testEmbededStructSchema() {
        let source: SourceFileSyntax =
                        """
                        /// Tasks
                        @AIModelOutput
                        struct AITasks {
                            /// Task items
                            let tasks: [AITask]
                        }
                        """
        let transformedSF = source.expand(macros: ["AIModelOutput": AIModelOutputMacro.self]) { _ in
            BasicMacroExpansionContext(sourceFiles: [source: file])
        }
        let expectedDescription =
                        #"""
                        /// Tasks
                        struct AITasks {
                            /// Task items
                            let tasks: [AITask]
                        }
                        
                        extension AITasks: AIModelOutput {
                            static var outputSchema: String {
                                """
                                {"type":"object","description":"Tasks","properties":{"tasks":{"type":"array","description":"Task items","items":\(AITask.outputSchema)}},"required":["tasks"]}
                                """
                            }
                        }
                        """#
        #expect(transformedSF.description == expectedDescription)
    }

    @Test
    func testRawTypeArraySchema() {
        let source: SourceFileSyntax =
                        """
                        /// Clarification questions to a task
                        @AIModelOutput
                        struct AIGoalClarification {
                            let questions: [String]?
                        }
                        """
        let transformedSF = source.expand(macros: ["AIModelOutput": AIModelOutputMacro.self]) { _ in
            BasicMacroExpansionContext(sourceFiles: [source: file])
        }
        let expectedDescription =
                        #"""
                        /// Clarification questions to a task
                        struct AIGoalClarification {
                            let questions: [String]?
                        }

                        extension AIGoalClarification: AIModelOutput {
                            static var outputSchema: String {
                                """
                                {"type":"object","description":"Clarification questions to a task","properties":{"questions":{"type":"array","description":"","items":{"type":"string"}}},"required":[]}
                                """
                            }
                        }
                        """#
        #expect(transformedSF.description == expectedDescription)
    }

    @Test
    func testObjectSchema() {
        let source: SourceFileSyntax =
                        """
                        @AIModelOutput
                        struct TestStruct: Codable {
                            let value: Int
                            let innerStruct: InnerStruct
                        }
                        """
        let transformedSF = source.expand(macros: ["AIModelOutput": AIModelOutputMacro.self]) { _ in
            BasicMacroExpansionContext(sourceFiles: [source: file])
        }
        let expectedDescription =
                        #"""

                        struct TestStruct: Codable {
                            let value: Int
                            let innerStruct: InnerStruct
                        }

                        extension TestStruct: AIModelOutput {
                            static var outputSchema: String {
                                """
                                {"type":"object","description":"","properties":{"value":{"type":"number","description":""},"innerStruct":\(InnerStruct.outputSchema)},"required":["value","innerStruct"]}
                                """
                            }
                        }
                        """#
        #expect(transformedSF.description == expectedDescription)
    }
}
