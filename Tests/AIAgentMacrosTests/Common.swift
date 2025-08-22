import SwiftSyntax
import SwiftSyntaxMacroExpansion

var file: BasicMacroExpansionContext.KnownSourceFile {
    BasicMacroExpansionContext.KnownSourceFile(
        moduleName: "MyModule",
        fullFilePath: "test.swift")
}
