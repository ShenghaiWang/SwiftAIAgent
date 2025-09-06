import Foundation

// Wrapper for storing strong typed value with type name
private struct StrongTypedValueFileWrapper: Codable {
    let typeName: String
    let jsonData: Data
}

// Registry for decoding strong typed values
public actor StrongTypedValueRegistry {
    public static var decoders: [String: (Data) -> (Sendable & Codable)?] = [:]
    public static func register<T: Sendable & Codable>(_ type: T.Type, typeName: String? = nil) {
        let name = typeName ?? String(describing: type)
        decoders[name] = { data in
            try? JSONDecoder().decode(type, from: data)
        }
    }
}

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
            case .strongTypedValue(let value):
                let valueFileURL = fileURL.appendingPathExtension("strongTypedValue")
                let typeName = String(describing: type(of: value))
                let jsonData = try JSONEncoder().encode(value)
                let wrapper = StrongTypedValueFileWrapper(typeName: typeName, jsonData: jsonData)
                let wrapperData = try JSONEncoder().encode(wrapper)
                try wrapperData.write(to: valueFileURL)
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
            case "strongTypedValue":
                let data = try Data(contentsOf: url)
                let wrapper = try JSONDecoder().decode(StrongTypedValueFileWrapper.self, from: data)
                guard let decoder = StrongTypedValueRegistry.decoders[wrapper.typeName],
                    let value = decoder(wrapper.jsonData)
                else {
                    return .text("[Unregistered strong typed value: \(wrapper.typeName)]")
                }
                return .strongTypedValue(value)
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
