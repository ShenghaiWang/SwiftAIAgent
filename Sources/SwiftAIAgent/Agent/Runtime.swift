import Foundation

actor Runtime {
    struct Cache {
        let title: String
        let output: [AIAgentOutput]
        let outputFiles: [String]
    }
    public static let shared = Runtime()
    private init() {}

    private var outputs: [UUID: Cache] = [:]

    func set(output: [AIAgentOutput], for uuid: UUID, title: String, useTempFiles: Bool = false) async throws {
        switch useTempFiles {
            case true:
                var outputFiles: [String] = []
                for value in output {
                    let file = try value.saveToFile()
                    outputFiles.append(file)
                }
                outputs[uuid] = .init(
                    title: title,
                    output: [],
                    outputFiles: outputFiles
                )
            case false:
                outputs[uuid] = .init(title: title, output: output, outputFiles: [])
        }
    }

    func output(of uuid: UUID) -> Cache? {
        outputs[uuid]
    }
}

extension Runtime.Cache {
    var cachedFiles: String {
        guard !outputFiles.isEmpty else { return "" }
        return
            """
            Agent `\(title)` has saved its result in the following files:
            \(outputFiles.map { "`\($0)`" }.joined(separator: ","))
            Use `readSavedOutput` tool to read them out when needed.
            """
    }
}
