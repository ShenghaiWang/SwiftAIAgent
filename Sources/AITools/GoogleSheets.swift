@preconcurrency import GoogleSheetsSwift
import Foundation
import AIAgentMacros

@AITool
public struct GoogleSheets: Sendable {
    let serviceAccount: String
    let sheetId: String
    private let googleSheetsClient: GoogleSheetsClient

    public init(serviceAccount: String, sheetId: String) throws {
        self.serviceAccount = serviceAccount
        self.sheetId = sheetId
        let tokenManager = try ServiceAccountTokenManager.loadFromFile(
            serviceAccount,
            useKeychain: false
        )
        self.googleSheetsClient = GoogleSheetsClient(tokenManager: tokenManager)
    }

    /// Append values to a range with simplified parameters
    /// - Parameters:
    ///   - range: The A1 notation range to append to
    ///   - values: 2D array of values to append
    /// - Returns: AppendValuesResponse containing append information
    /// - Throws: GoogleSheetsError if the operation fails
    func appendToRange(values: [[String]], range: String) async throws {
        _ = try await googleSheetsClient.appendToRange(
            sheetId,
            range: range,
            values: values,
            majorDimension: .rows,
            valueInputOption: .userEntered
        )
    }
}
