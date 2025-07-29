import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing
import AIAgentMacroDefinitions

struct AIToolMacroTests {
    @Test("Tool Macro Test")
    func toolMacroTest() {
        let source: SourceFileSyntax =
                        """
                        @AITool
                        struct ToolStruct {
                            func getWeather(location: String) -> Weather {
                            }
                        }
                        """
        let transformedSF = source.expand(macros: ["AITool": AIToolMacro.self]) { _ in
            BasicMacroExpansionContext(sourceFiles: [source: file])
        }
        let expectedDescription =
                        #"""
                        
                        func test() {
                            logger.trace(message: "\(#function)")
                            let a = 10 * 10
                            return a
                        }
                        """#
        #expect(transformedSF.description == expectedDescription)
    }
}
