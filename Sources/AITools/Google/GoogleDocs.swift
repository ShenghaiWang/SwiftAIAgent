import GoogleDocsSDK
import Foundation
import AIAgentMacros

@AITool
public struct GoogleDocs: Sendable, GoogleClient {
    let documentId: String
    let googleDocsClient: Client

    /// Initializes a `GoogleDocs` client using a service account.
    ///
    /// - Parameters:
    ///   - serviceAccount: The path or identifier for the service account credentials.
    ///   - documentId: The ID of the Google Docs document to operate on.
    /// - Throws: An error if the client could not be initialized.
    public init(serviceAccount: String, documentId: String) throws {
        self.documentId = documentId
        self.googleDocsClient = try Self.client(serviceAccount: serviceAccount)
    }

    /// Initializes a `GoogleDocs` client using OAuth credentials.
    ///
    /// - Parameters:
    ///   - clientId: The OAuth client ID.
    ///   - clientSecret: The OAuth client secret.
    ///   - redirectURI: The redirect URI for OAuth authentication. Defaults to `http://localhost`.
    ///   - documentId: The ID of the Google Docs document to operate on.
    /// - Throws: An error if the client could not be initialized.
    public init(
        clientId: String,
        clientSecret: String,
        redirectURI: String = "http://localhost",
        documentId: String,
    ) async throws {
        self.documentId = documentId
        self.googleDocsClient = try await Self.client(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: redirectURI
        )
    }

    // Update Google Slides
    /// - Parameters:
    ///   - requests:The requests of update Google slides
    /// - Throws: Error if the operation fails
    private func docs_documents_batchUpdate(
        requests: [Components.Schemas.Request]
    ) async throws
        -> String
    {
        _ = try await googleDocsClient.docs_documents_batchUpdate(
            documentId: documentId,
            requests: requests
        )
        return "Successfully finished"  // Ignore error for now
    }

    /// Instert text as a new paragraph
    /// - Parameters:
    ///  - text: The text to be added
    ///  - fontSettings: font settings
    ///  - foregroundColor: the foregroundColor of the text
    ///  - backgroundColor: the backgroundColor of the text
    func insertParagraph(
        text: String,
        fontSettings: FontSettings?,
        foregroundColor: RgbColor?,
        backgroundColor: RgbColor?,
    ) async throws -> String {
        let insertTextRequest = Components.Schemas.Request(
            insertText:
                .init(
                    endOfSegmentLocation: .init(segmentId: nil),
                    location: nil,
                    text: "\n\(text)"
                )
        )
        _ = try await googleDocsClient.docs_documents_batchUpdate(
            documentId: documentId,
            requests: [insertTextRequest]
        )
        let document = try await googleDocsClient.docs_documents_get(documentId: documentId)
        let updateTextStyle = Components.Schemas.Request(
            updateTextStyle: .init(
                fields: "*",
                range: .init(
                    endIndex: document.body?.content?.last?.endIndex ?? 0,
                    startIndex: document.body?.content?.last?.startIndex ?? 0
                ),
                textStyle: .init(
                    backgroundColor: backgroundColor?.color,
                    bold: fontSettings?.bold == 1,
                    fontSize: .init(magnitude: fontSettings?.fontSize, unit: .pt),
                    foregroundColor: foregroundColor?.color,
                    italic: fontSettings?.italic == 1,
                    strikethrough: fontSettings?.strikethrough == 1,
                    underline: fontSettings?.underline == 1,
                    weightedFontFamily: .init(
                        fontFamily: fontSettings?.fontFamily,
                        weight: fontSettings?.fontWeight
                    )
                )
            )
        )
        return try await docs_documents_batchUpdate(
            requests: [updateTextStyle],
        )
    }
}

private extension RgbColor {
    /// Converts the `RgbColor` to a `Components.Schemas.OptionalColor` for use in Google Docs API requests.
    var color: Components.Schemas.OptionalColor {
        .init(color: .init(rgbColor: .init(blue: blue, green: green, red: red)))
    }
}
