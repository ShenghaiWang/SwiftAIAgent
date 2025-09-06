import AIAgentMacros
import Foundation

/// Retrieve AIAgentOutput from file
@AITool
public struct AIAgentOutputIO {
    /// Retrieve AIAgentOutput from file with absolute path. Use this tool to read the content of the saved LLM output
    /// - Parameters:
    ///  - file: the absolute file path & name
    /// - Returns: the AIAgentOutput that saved in file
    func readSavedOutput(file: String) throws -> String? {
        guard let result = try AIAgentOutput.readFromFile(file)?.output else { return nil }
        return
            """
            Content of file \(file):
            <file_content>
            \(result)
            </file_content>
            """
    }
}
