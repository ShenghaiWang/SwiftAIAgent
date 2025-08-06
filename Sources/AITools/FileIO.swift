import Foundation
import AIAgentMacros

/// File IO tool
@AITool
public struct FileIO {
    let baseFolder: String

    public init(baseFolder: String) {
        self.baseFolder = baseFolder
    }

    public func read(file: String) throws -> String? {
        let fileURL = URL(fileURLWithPath: baseFolder).appendingPathComponent(file)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    public func write(to file: String, content: String) throws {
        let fileURL = URL(fileURLWithPath: baseFolder).appendingPathComponent(file)
        try Data(content.utf8).write(to: fileURL)
    }
}
