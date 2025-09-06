import Foundation
import AIAgentMacros
import GoogleCalendarSDK

@AITool
public struct GoogleCalendar: Sendable, GoogleClient {
    enum Error: Swift.Error {
        case invalidDateFormat
    }
    private let googleCalendarClient: Client
    private let calendarId: String

    /// Initializes a `GoogleCalendar` client using a service account.
    ///
    /// - Parameter serviceAccount: The path or identifier for the service account credentials.
    /// - Throws: An error if the client could not be initialized.
    public init(
        serviceAccount: String,
        calendarId: String
    ) throws {
        self.calendarId = calendarId
        self.googleCalendarClient = try Self.client(serviceAccount: serviceAccount)
    }

    /// Initializes a `GoogleCalendar` client using OAuth credentials.
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
        calendarId: String,
    ) async throws {
        self.calendarId = calendarId
        self.googleCalendarClient = try await Self.client(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: redirectURI
        )
    }

    /// Inserts an event into the user's primary Google Calendar.
    ///
    /// - Parameters:
    ///   - summary: The summary or title of the event.
    ///   - description: The description of the event.
    ///   - start: The start date and time of the event in ISO8601 format with Timezone information.
    ///   - end: The end date and time of the event in ISO8601 format with Timezone information.
    ///   - location: The location of the event.
    ///   - attendees: A list of attendee email addresses.
    /// - Returns: A string representing the result of the event insertion.
    /// - Throws: An error if the operation fails.
    func calendar_events_insert(
        summary: String,
        description: String,
        start: String,
        end: String,
        location: String,
        attendees: [String]
    ) async throws -> String {
        guard let startDate = ISO8601DateFormatter().date(from: start),
            let endDate = ISO8601DateFormatter().date(from: end)
        else {
            throw Error.invalidDateFormat
        }
        let result = try await googleCalendarClient.calendar_events_insert(
            calendarId: calendarId,
            summary: summary,
            description: description,
            start: startDate,
            end: endDate,
            location: location,
            attendees: attendees
        )
        return "Successfully inserted event: \(result)"
    }
}
