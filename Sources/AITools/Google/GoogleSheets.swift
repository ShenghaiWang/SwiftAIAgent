import GoogleSheetsSDK
import Foundation
import AIAgentMacros

@AITool
public struct GoogleSheets: Sendable, GoogleClient {
    let sheetId: String
    private let googleSheetsClient: Client

    /// Initializes a `GoogleSheets` client using a service account.
    ///
    /// - Parameters:
    ///   - serviceAccount: The path or identifier for the service account credentials.
    ///   - sheetId: The ID of the Google Sheets spreadsheet to operate on.
    /// - Throws: An error if the client could not be initialized.
    public init(serviceAccount: String, sheetId: String) throws {
        self.sheetId = sheetId
        self.googleSheetsClient = try Client(accountServiceFile: serviceAccount)
    }

    /// Initializes a `GoogleSheets` client using OAuth credentials.
    ///
    /// - Parameters:
    ///   - clientId: The OAuth client ID.
    ///   - clientSecret: The OAuth client secret.
    ///   - redirectURI: The redirect URI for OAuth authentication. Defaults to `http://localhost`.
    ///   - sheetId: The ID of the Google Sheets spreadsheet to operate on.
    /// - Throws: An error if the client could not be initialized.
    public init(
        clientId: String,
        clientSecret: String,
        redirectURI: String = "http://localhost",
        sheetId: String,
    ) async throws {
        self.sheetId = sheetId
        self.googleSheetsClient = try await Self.client(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: redirectURI
        )
    }

    /// Append values to a range with simplified parameters
    /// - Parameters:
    ///   - values: 2D array of values to append
    ///   - range: The A1 notation range to append to
    /// - Returns: AppendValuesResponse containing append information
    /// - Throws: Error if the operation fails
    func appendToRange(values: [[String]], range: String) async throws {
        _ = try await googleSheetsClient.sheets_spreadsheets_values_append(
            spreadsheetId: sheetId,
            sheetName: "Sheet1",
            values: values.map { try $0.map { try .init(unvalidatedValue: $0) } }
        )
    }
}
