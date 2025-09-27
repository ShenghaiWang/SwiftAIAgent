import Testing
import Foundation
@testable import SwiftAIAgent

private struct DummyStruct: Codable, Sendable, Equatable {
    let value: String
}

@Suite("AIAgentOutput file persistence")
struct AIAgentOutputFileTests {
    @Test("Save and read text output")
    func saveAndReadText() throws {
        let output = AIAgentOutput.text("Hello, world!")
        let filePath = try output.saveToFile()
        let readOutput = try AIAgentOutput.readFromFile(filePath)
        #expect(readOutput?.output == "Hello, world!")
    }

    @Test("Save and read function calls output")
    func saveAndReadFunctionCalls() throws {
        let calls = ["func1", "func2"]
        let output = AIAgentOutput.functionCalls(calls)
        let filePath = try output.saveToFile()
        let readOutput = try AIAgentOutput.readFromFile(filePath)
        #expect(readOutput?.output == nil)
    }

    @Test("Save and read strong typed value output")
    func saveAndReadStrongTypedValue() throws {
        let dummy = DummyStruct(value: "test123")
        let output = AIAgentOutput.strongTypedValue(dummy)
        let filePath = try output.saveToFile()
        let readOutput = try AIAgentOutput.readFromFile(filePath)
        #expect(readOutput?.output == "{\"value\":\"test123\"}")
    }

    @Test("Save and read image output")
    func saveAndReadImage() throws {
        let data = Data([0x01, 0x02, 0x03])
        let output = AIAgentOutput.image(data)
        let filePath = try output.saveToFile()
        let readOutput = try AIAgentOutput.readFromFile(filePath)
        if case let .image(readData) = readOutput {
            #expect(readData == data)
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Save and read audio output")
    func saveAndReadAudio() throws {
        let data = Data([0x0A, 0x0B, 0x0C])
        let output = AIAgentOutput.audio(data)
        let filePath = try output.saveToFile()
        let readOutput = try AIAgentOutput.readFromFile(filePath)
        if case let .audio(readData) = readOutput {
            #expect(readData == data)
        } else {
            #expect(Bool(false))
        }
    }
}
