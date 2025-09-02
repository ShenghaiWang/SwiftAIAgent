import GoogleSlidesSDK
import Foundation
import AIAgentMacros

@AITool
public struct GoogleSlides: Sendable, GoogleClient {
    /// Size of a rectengle
    @AIModelSchema
    struct Size {
        /// The width of the rectangle, capped at 700.
        let width: Double
        /// The width of the rectangle, capped at 400.
        let height: Double
    }

    /// The location of an element
    @AIModelSchema
    struct Position {
        /// the x offset
        let x: Double
        /// the y offset
        let y: Double
    }

    let presentationId: String
    private let googleSlidesClient: Client

    /// Initializes a `GoogleSlides` client using a service account.
    ///
    /// - Parameters:
    ///   - serviceAccount: The path or identifier for the service account credentials.
    ///   - presentationId: The ID of the Google Slides presentation to operate on.
    /// - Throws: An error if the client could not be initialized.
    public init(serviceAccount: String, presentationId: String) throws {
        self.presentationId = presentationId
        self.googleSlidesClient = try Self.client(serviceAccount: serviceAccount)
    }

    /// Initializes a `GoogleSlides` client using OAuth credentials.
    ///
    /// - Parameters:
    ///   - clientId: The OAuth client ID.
    ///   - clientSecret: The OAuth client secret.
    ///   - redirectURI: The redirect URI for OAuth authentication. Defaults to `http://localhost`.
    ///   - presentationId: The ID of the Google Slides presentation to operate on.
    /// - Throws: An error if the client could not be initialized.
    public init(
        clientId: String,
        clientSecret: String,
        redirectURI: String = "http://localhost",
        presentationId: String,
    ) async throws {
        self.presentationId = presentationId
        self.googleSlidesClient = try await Self.client(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: redirectURI
        )
    }

    /// Sends a batch update request to the Google Slides API for the specified presentation.
    ///
    /// - Parameter requests: The requests to apply to the Google Slides presentation.
    /// - Returns: A string indicating the result of the operation.
    /// - Throws: An error if the operation fails.
    private func batchUpdateSlides(requests: [Components.Schemas.Request]) async throws -> String {
        let result = try await googleSlidesClient.slides_presentations_batchUpdate(
            presentationId: presentationId,
            requests: requests
        )
        return "\(result)"  // Ignore error for now
    }

    /// Creates a new slide in the current presentation.
    ///
    /// - Returns: The ID of the newly created slide.
    /// - Throws: An error if the operation fails.
    func creatANewSlide() async throws -> String {
        let id = UUID().uuidString
        _ = try await batchUpdateSlides(requests: [
            .init(createSlide: .init(objectId: id))
        ])
        return id
    }

    /// Inserts text into a slide.
    ///
    /// - Parameters:
    ///   - slideId: The ID of the slide to add text to.
    ///   - text: The text to be added to the slide.
    ///   - fontSettings: Font settings to apply to the text.
    ///   - size: The size of the text region.
    ///   - position: The position of the text region.
    ///   - foregroundColor: The foreground color of the text.
    ///   - backgroundColor: The background color of the text.
    /// - Returns: A string indicating the result of the operation.
    /// - Throws: An error if the operation fails.
    func insertTextToSlide(
        slideId: String,
        text: String,
        fontSettings: FontSettings?,
        size: Size,
        position: Position,
        foregroundColor: RgbColor?,
        backgroundColor: RgbColor?,
    ) async throws -> String {
        let id = UUID().uuidString
        var result = try await batchUpdateSlides(
            requests: [
                .init(
                    createShape:
                        .init(
                            elementProperties: .init(
                                size: size,
                                position: position,
                                objectId: slideId
                            ),
                            objectId: id,
                            shapeType: .textBox,
                        )
                ),
                .init(
                    insertText:
                        .init(
                            insertionIndex: 0,
                            objectId: id,
                            text: text
                        )
                ),
            ])
        if let fontSettings {
            result += try await batchUpdateSlides(
                requests: [
                    .init(
                        updateTextStyle:
                            .init(
                                fields: "*",
                                objectId: id,
                                style: .init(
                                    bold: fontSettings.bold == 1,
                                    fontSize: .init(magnitude: fontSettings.fontSize, unit: .pt),
                                    foregroundColor: foregroundColor?.color,
                                ),
                                textRange: .init(_type: .all)
                            )
                    )
                ])
        }
        result += try await batchUpdateSlides(requests: [
            .init(
                updateShapeProperties:
                    .init(
                        fields: "autofit.autofitType",
                        objectId: id,
                        shapeProperties: .init(
                            autofit: .init(
                                autofitType: Components.Schemas.Autofit.AutofitTypePayload.none
                            )
                        ),
                    )
            )
        ])
        return result
    }

    /// Inserts an image into a slide.
    ///
    /// - Parameters:
    ///   - slideId: The ID of the slide to add the image to.
    ///   - imageUrl: The URL of the image to be added to the slide.
    ///   - size: The size of the image region.
    ///   - position: The position of the image region.
    /// - Returns: A string indicating the result of the operation.
    /// - Throws: An error if the operation fails.
    func insertImageToSlide(
        slideId: String,
        imageUrl: String,
        size: Size,
        position: Position
    ) async throws -> String {
        let id = UUID().uuidString
        return try await batchUpdateSlides(
            requests: [
                .init(
                    createImage: .init(
                        elementProperties: .init(size: size, position: position, objectId: slideId),
                        objectId: id,
                        url: imageUrl
                    )
                )
            ])
    }
}

extension Components.Schemas.PageElementProperties {
    /// Initializes `PageElementProperties` with the given size and position.
    ///
    /// - Parameters:
    ///   - size: The size of the element.
    ///   - position: The position of the element.
    ///   - objectId: The object ID of the page element (optional).
    init(size: GoogleSlides.Size, position: GoogleSlides.Position, objectId: String? = nil) {
        self.init(
            pageObjectId: objectId,
            size: .init(
                height: .init(magnitude: size.height, unit: .pt),
                width: .init(magnitude: size.width, unit: .pt)
            ),
            transform: .init(
                scaleX: 1,
                scaleY: 1,
                translateX: position.x,
                translateY: position.y,
                unit: .pt
            )
        )
    }
}

private extension RgbColor {
    /// Converts the `RgbColor` to a `Components.Schemas.OptionalColor` for use in Google Slides API requests.
    var color: Components.Schemas.OptionalColor {
        .init(opaqueColor: .init(rgbColor: .init(blue: blue, green: green, red: red)))
    }
}
