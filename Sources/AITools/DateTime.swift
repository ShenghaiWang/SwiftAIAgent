import AIAgentMacros
import Foundation

/// A tool that provides current date and time
@AITool
public struct DateTime {
    public init() {}
    /// A tool to get the current date and time
    /// - Returns: the current date and time in ISO8601Format
    public func currentDateTime() throws -> String {
        Date().ISO8601Format()
    }
}
