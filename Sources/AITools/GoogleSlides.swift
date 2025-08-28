import GoogleSlidesSDK
import Foundation
import AIAgentMacros

@AITool
public struct GoogleSlides: Sendable {
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

    let serviceAccount: String
    let presentationId: String
    private let googleSlidesClient: Client

    public init(serviceAccount: String, presentationId: String) throws {
        self.serviceAccount = serviceAccount
        self.presentationId = presentationId
        self.googleSlidesClient = try Client(accountServiceFile: serviceAccount)
    }

    /// Update Google Slides
    /// - Parameters:
    ///   - requests:The requests of update Google slides
    /// - Throws: GoogleSheetsError if the operation fails
    private func batchUpdateSlides(requests: [Components.Schemas.Request]) async throws -> String {
        _ = try await googleSlidesClient.slides_presentations_batchUpdate(
            presentationId: presentationId,
            requests: requests
        )
        return "Successfully finished"  // Ignore error for now
    }

    /// Create a new slide in the current slide
    /// - Parameters
    ///  - request: the request to create a new slide
    /// - Throws: GoogleSheetsError if the operation fails
    /// - Returns: The ID of the newly created slide
    func creatANewSlide() async throws -> String {
        let id = UUID().uuidString
        _ = try await batchUpdateSlides(requests: [
            .init(createSlide: .init(objectId: id))
        ])
        return id
    }

    /// Insert text to slides
    /// - Parameters:
    ///  - slideId: the id of the slide to be used for adding text
    ///  - text: the text to be added to the slide
    ///  - isTitle: `0` or `1`, `1` if the text is a title
    ///  - size: the size of the text region, the size given needs to honur the position value so that the content not to overflow
    ///  - position: the postion of the text region
    /// - Throws: GoogleSheetsError if the operation fails
    /// - Returns: Operation status
    func insertTextToSlide(
        slideId: String,
        text: String,
        isTitle: Int = 0,  // use `Int` type just to tolerate LLM. It's more reliable to use 0/1 for bool values
        size: Size,
        position: Position,
    ) async throws -> String {
        let id = UUID().uuidString
        let result = try await batchUpdateSlides(
            requests: [
                .init(
                    createShape:
                        .init(
                            elementProperties: .init(
                                size: size, position: position, objectId: slideId),
                            objectId: id,
                            shapeType: .textBox,
                        )),
                .init(
                    insertText:
                        .init(
                            insertionIndex: 0,
                            objectId: id,
                            text: text)),
            ])
        guard isTitle == 1 else { return result }
        return try await batchUpdateSlides(
            requests: [
                .init(
                    updateTextStyle:
                        .init(
                            fields: "*",
                            objectId: id,
                            style: .init(
                                bold: true,
                                fontSize: .init(magnitude: 30, unit: .pt)
                            ),
                            textRange: .init(_type: .all)
                        ))
            ])
    }

    /// Insert Image to slides
    /// - Parameters:
    ///  - slideId: the id of the slide to be used for adding image
    ///  - imageUrl: the url of the image to be added to the slide
    ///  - size: the size of the image region, the size given needs to honur the position value so that the content not to overflow
    ///  - position: the postion of the image region
    /// - Throws: GoogleSheetsError if the operation fails
    /// - Returns: Operation status
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
                        url: imageUrl))
            ])
    }
}

extension Components.Schemas.PageElementProperties {
    init(size: GoogleSlides.Size, position: GoogleSlides.Position, objectId: String? = nil) {
        self.init(
            pageObjectId: objectId,
            size: .init(
                height: .init(magnitude: size.height, unit: .pt),
                width: .init(magnitude: size.width, unit: .pt)
            ),
            transform: .init(
                scaleX: 1, scaleY: 1,
                translateX: position.x, translateY: position.y,
                unit: .pt
            )
        )
    }
}
