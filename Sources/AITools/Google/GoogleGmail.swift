import Foundation
import AIAgentMacros
import GoogleGmailSDK

@AITool
public struct GoogleGmail: Sendable, GoogleClient {
    private let googleGmailClient: Client

    /// Initializes a `GoogleGmail` client using OAuth credentials.
    ///
    /// - Parameters:
    ///   - clientId: The OAuth client ID.
    ///   - clientSecret: The OAuth client secret.
    ///   - redirectURI: The redirect URI for OAuth authentication. Defaults to `http://localhost`.
    /// - Throws: An error if the client could not be initialized.
    public init(
        clientId: String,
        clientSecret: String,
        redirectURI: String = "http://localhost",
    ) async throws {
        self.googleGmailClient = try await Self.client(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: redirectURI
        )
    }

    /// Creates a draft email in Gmail.
    ///
    /// - Parameters:
    ///   - to: The recipient's email address.
    ///   - subject: The subject of the email.
    ///   - body: The body content of the email.
    /// - Returns: A string representing the result of the draft creation.
    /// - Throws: An error if the operation fails.
    func gmail_users_drafts_create(
        to: String,
        subject: String,
        body: String
    ) async throws -> String {
        let result = try await googleGmailClient.gmail_users_drafts_create(
            to: [to],
            subject: subject,
            body: body
        )
        return "Successfully created draft: \(result)"
    }
}
