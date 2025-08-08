import Foundation

public enum Error: Swift.Error {
    case invalidResponse(responseStatusCode: Int?)
    case invalidData
}
