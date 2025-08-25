import GoogleSheetsSDK
import Foundation
import AIAgentMacros

@AITool
public struct GoogleSheets: Sendable {
    let serviceAccount: String
    let sheetId: String
    private let googleSheetsClient: Client

    public init(serviceAccount: String, sheetId: String) throws {
        self.serviceAccount = serviceAccount
        self.sheetId = sheetId
        self.googleSheetsClient = try Client(accountServiceFile: serviceAccount)
    }

    /// Append values to a range with simplified parameters
    /// - Parameters:
    ///   - values: 2D array of values to append
    ///   - range: The A1 notation range to append to
    /// - Returns: AppendValuesResponse containing append information
    /// - Throws: GoogleSheetsError if the operation fails
    func appendToRange(values: [[String]], range: String) async throws {
        _ = try await googleSheetsClient.sheets_spreadsheets_values_append(
            spreadsheetId: sheetId,
            sheetName: "Sheet1",
            values: values.map { try $0.map { try .init(unvalidatedValue: $0) }  }
        )
    }
}
