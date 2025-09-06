import AIAgentMacros
import Foundation

/// File IO tool that can only read files that relates to `base folder` that it initialsed
@AITool
public struct FileIO {
    let baseFolder: String

    public init(baseFolder: String) {
        self.baseFolder = baseFolder
    }

    /// Read content of a file that under the `base folder`
    /// - Parameter file: the file name, relative to `base folder`
    /// - Returns: the content of the file
    public func read(file: String) throws -> String? {
        let fileURL = URL(fileURLWithPath: baseFolder).appendingPathComponent(file)
        return
            """
                Content of file:
                \(try String(contentsOf: fileURL, encoding: .utf8))
            """
    }

    /// Write content to the file of the specified fileName
    /// This tool knows the folder to save the file
    /// - Parameters:
    ///  - fileName: the file name, relative to base folder
    ///  - content: the content to be written to the file
    public func write(fileName: String, content: String) throws -> String {
        let fileURL = URL(fileURLWithPath: baseFolder).appendingPathComponent(fileName)
        try Data(content.utf8).write(to: fileURL)
        return "Successfully written to \(fileName)"
    }
}
