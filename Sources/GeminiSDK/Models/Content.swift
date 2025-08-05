import Foundation

public struct Content: Codable {
    public struct Part {
        public struct InlineData: Codable {
            let mimeType: String
            /// The base64-encoded data.
            let data: String

            public init(mimeType: String, data: String) {
                self.mimeType = mimeType
                self.data = data
            }
        }
        public struct FileData: Codable {
            let mimeType: String
            let fileUri: String

            public init(mimeType: String, fileUri: String) {
                self.mimeType = mimeType
                self.fileUri = fileUri
            }
        }
        public struct ExecutableCode: Codable {
            public enum Language: String, Codable {
                case python = "PYTHON"
                case unspecified = "LANGUAGE_UNSPECIFIED"
            }
            let language: Language
            let code: String

            public init(language: Language, code: String) {
                self.language = language
                self.code = code
            }
        }
        public struct FunctionResponse: Codable {
            public enum Scheduling: String, Codable {
                case unspecified = "SCHEDULING_UNSPECIFIED"
                case silent = "SILENT"
                case idle = "WHEN_IDLE"
                case interupt = "INTERRUPT"
            }
            let id: String
            let name: String
            let response: String
            let willContinue: Bool
            let scheduling: Scheduling

            public init(id: String, name: String, response: String, willContinue: Bool, scheduling: Scheduling) {
                self.id = id
                self.name = name
                self.response = response
                self.willContinue = willContinue
                self.scheduling = scheduling
            }
        }
        public struct CodeExecutionResult: Codable {
            public enum Outcome: String, Codable {
                case unspecified = "OUTCOME_UNSPECIFIED"
                case ok = "OUTCOME_OK"
                case failed = "OUTCOME_FAILED"
                case timeout = "OUTCOME_DEADLINE_EXCEEDED"
            }
            let outcome: Outcome
            let output: String

            public init(outcome: Outcome, output: String) {
                self.outcome = outcome
                self.output = output
            }
        }
        let text: String?
        let inlineData: InlineData?
        let functionCall: String?
        let functionResponse: FunctionResponse?
        let fileData: FileData?
        let executableCode: ExecutableCode?
        let codeExecutionResult: CodeExecutionResult?

        public init(text: String?,
                    inlineData: InlineData? = nil,
                    functionCall: String? = nil,
                    functionResponse: FunctionResponse? = nil,
                    fileData: FileData? = nil,
                    executableCode: ExecutableCode? = nil,
                    codeExecutionResult: CodeExecutionResult? = nil) {
            self.text = text
            self.inlineData = inlineData
            self.functionCall = functionCall
            self.functionResponse = functionResponse
            self.fileData = fileData
            self.executableCode = executableCode
            self.codeExecutionResult = codeExecutionResult
        }
    }
    let parts: [Part]
    let role: String?

    public init(parts: [Part], role: String? = nil) {
        self.parts = parts
        self.role = role
    }
}

extension Content.Part: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try? container.decode(String.self, forKey: .text)
        inlineData = try? container.decodeIfPresent(InlineData.self, forKey: .inlineData)
        functionCall = nil
        functionResponse = try? container.decodeIfPresent(FunctionResponse.self, forKey: .functionResponse)
        fileData = try? container.decodeIfPresent(FileData.self, forKey: .fileData)
        executableCode = try? container.decodeIfPresent(ExecutableCode.self, forKey: .executableCode)
        codeExecutionResult = try? container.decodeIfPresent(CodeExecutionResult.self, forKey: .codeExecutionResult)
    }
}
