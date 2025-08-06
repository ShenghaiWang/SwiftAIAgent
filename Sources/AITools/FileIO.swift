import Foundation
import AIAgentMacros

/// File IO tool
@AITool
public struct FileIO {
    let baseFolder: String

    public init(baseFolder: String) {
        self.baseFolder = baseFolder
    }

    /// Read content of a file
    /// - Parameter file: the file name, relative to base folder
    /// - Returns: the content of the file
    public func read(file: String) throws -> String? {
        let fileURL = URL(fileURLWithPath: baseFolder).appendingPathComponent(file)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    /// Write content to the file
    /// - Parameters:
    ///  - file: the file name, relative to base folder
    ///  - content: the content to be written to the file
    public func write(to file: String, content: String) throws -> String {
        let fileURL = URL(fileURLWithPath: baseFolder).appendingPathComponent(file)
        try Data(content.utf8).write(to: fileURL)
        return "Successfully written to \(file)"
    }
}
