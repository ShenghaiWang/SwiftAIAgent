import GoogleSlidesSDK
import Foundation
import AIAgentMacros

@AITool
public struct GoogleSlides: Sendable {
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
    /// - Parameters
    ///  - slideId: the id of the slide to be used for adding text
    ///  - text: the text to be added to the slide
    ///  - size: the size of the text region
    ///  - position: the postion of the text region
    /// - Throws: GoogleSheetsError if the operation fails
    /// - Returns: Operation status
    func insertTextToSlide(
        slideId: String,
        text: String,
        size: Size,
        position: Position
    ) async throws -> String {
        let id = UUID().uuidString
        return try await batchUpdateSlides(
            requests: [
                .init(
                    createShape:
                        .init(
                            elementProperties: .init(
                                pageObjectId: slideId,
                                size: .init(
                                    height: .init(magnitude: size.height, unit: .pt),
                                    width: .init(magnitude: size.width, unit: .pt)
                                ),
                                transform: .init(
                                    scaleX: 1, scaleY: 1,
                                    translateX: position.x, translateY: position.y,
                                    unit: .pt
                                )
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
                            text: text)
                ),
            ])
    }

    /// Insert Image to slides
    /// - Parameters
    ///  - slideId: the id of the slide to be used for adding image
    ///  - imageUrl: the url of the image to be added to the slide
    ///  - size: the size of the image region
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
                    createImage:
                        .init(
                            elementProperties: .init(
                                pageObjectId: slideId,
                                size: .init(
                                    height: .init(magnitude: size.height, unit: .pt),
                                    width: .init(magnitude: size.width, unit: .pt)
                                ),
                                transform: .init(
                                    scaleX: 1, scaleY: 1,
                                    translateX: position.x, translateY: position.y,
                                    unit: .pt
                                )
                            ),
                            objectId: id,
                            url: imageUrl
                        )
                )
            ])
    }
}

/// Size of a rectengle
@AIModelSchema
struct Size {
    /// The width of the rectangle, capped at 1000.
    let width: Double
    /// The width of the rectangle, capped at 600.
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
