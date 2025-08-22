import AIAgentMacroDefinitions
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing

struct TraceMacroTests {
    @Test
    func InvalidTraceMacroTest() {
        let source: SourceFileSyntax =
            """
            @Traced(by: logger)
            struct A {
            }
            """
        let transformedSF = source.expand(macros: ["Traced": TraceMacro.self]) { _ in
            BasicMacroExpansionContext(sourceFiles: [source: file])
        }
        let expectedDescription =
            #"""

            struct A {
            }
            """#
        #expect(transformedSF.description == expectedDescription)
    }

    @Test
    func TraceMacroTest() {
        let source: SourceFileSyntax =
            """
            @Traced(by: logger)
            func test() {
                let a = 10 * 10
                return a
            }
            """
        let transformedSF = source.expand(macros: ["Traced": TraceMacro.self]) { _ in
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
