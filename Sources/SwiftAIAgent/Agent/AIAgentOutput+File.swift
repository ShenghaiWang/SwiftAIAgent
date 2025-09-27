import Foundation

extension AIAgentOutput {
    func saveToFile() throws -> String {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
        switch self {
            case .text(let string):
                let textFileURL = fileURL.appendingPathExtension("txt")
                try string.write(to: textFileURL, atomically: true, encoding: .utf8)
                return textFileURL.path
            case .functionCalls:
                return "No need to save function calls"
            case .strongTypedValue(let value):  // Save it in json string format
                let valueFileURL = fileURL.appendingPathExtension("txt")
                let jsonData = try JSONEncoder().encode(value)
                let string = String(data: jsonData, encoding: .utf8)!
                try string.write(to: valueFileURL, atomically: true, encoding: .utf8)
                return valueFileURL.path
            case .image(let data):
                let imageFileURL = fileURL.appendingPathExtension("imageData")
                try data.write(to: imageFileURL)
                return imageFileURL.path
            case .audio(let data):
                let audioFileURL = fileURL.appendingPathExtension("audioData")
                try data.write(to: audioFileURL)
                return audioFileURL.path
        }
    }

    static func readFromFile(_ filePath: String) throws -> AIAgentOutput? {
        let url = URL(fileURLWithPath: filePath)
        let ext = url.pathExtension
        switch ext {
            case "txt":
                let string = try String(contentsOf: url, encoding: .utf8)
                return .text(string)
            case "funcResult":
                let data = try Data(contentsOf: url)
                let array = try JSONDecoder().decode([String].self, from: data)
                return .functionCalls(array)
            case "imageData":
                let data = try Data(contentsOf: url)
                return .image(data)
            case "audioData":
                let data = try Data(contentsOf: url)
                return .audio(data)
            default:
                return nil
        }
    }
}
