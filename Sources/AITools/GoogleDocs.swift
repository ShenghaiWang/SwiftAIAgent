import GoogleDocsSDK
import Foundation
import AIAgentMacros

@AITool
public struct GoogleDocs {
    let serviceAccount: String
    let documentId: String
    let googleDocsClient: Client

    public init(serviceAccount: String, documentId: String) throws {
        self.serviceAccount = serviceAccount
        self.documentId = documentId
        self.googleDocsClient = try Client(accountServiceFile: serviceAccount)
    }

    // Update Google Slides
    /// - Parameters:
    ///   - requests:The requests of update Google slides
    /// - Throws: Error if the operation fails
    private func docs_documents_batchUpdate(requests: [Components.Schemas.Request]) async throws
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
                    startIndex: document.body?.content?.last?.startIndex ?? 0),
                textStyle: .init(
                    backgroundColor: backgroundColor?.color,
                    bold: fontSettings?.bold == 1,
                    fontSize: .init(magnitude: fontSettings?.fontSize, unit: .pt),
                    foregroundColor: foregroundColor?.color,
                    italic: fontSettings?.italic == 1,
                    strikethrough: fontSettings?.strikethrough == 1,
                    underline: fontSettings?.underline == 1,
                    weightedFontFamily: .init(
                        fontFamily: fontSettings?.fontFamily, weight: fontSettings?.fontWeight)
                )
            )
        )
        return try await docs_documents_batchUpdate(
            requests: [updateTextStyle],
        )
    }
}

private extension RgbColor {
    var color: Components.Schemas.OptionalColor {
        .init(color: .init(rgbColor: .init(blue: blue, green: green, red: red)))
    }
}
