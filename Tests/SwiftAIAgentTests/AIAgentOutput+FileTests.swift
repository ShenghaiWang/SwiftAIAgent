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
        let readOutput = try output.readFromFile(filePath)
        #expect(readOutput.output == "Hello, world!")
    }

    @Test("Save and read function calls output")
    func saveAndReadFunctionCalls() throws {
        let calls = ["func1", "func2"]
        let output = AIAgentOutput.functionCalls(calls)
        let filePath = try output.saveToFile()
        let readOutput = try output.readFromFile(filePath)
        #expect(readOutput.output == calls.joined(separator: "||"))
    }

    @Test("Save and read strong typed value output")
    func saveAndReadStrongTypedValue() throws {
        StrongTypedValueRegistry.register(DummyStruct.self)
        let dummy = DummyStruct(value: "test123")
        let output = AIAgentOutput.strongTypedValue(dummy)
        let filePath = try output.saveToFile()
        let readOutput = try output.readFromFile(filePath)
        if case let .strongTypedValue(decoded) = readOutput,
            let decodedDummy = decoded as? DummyStruct
        {
            #expect(decodedDummy == dummy)
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Save and read image output")
    func saveAndReadImage() throws {
        let data = Data([0x01, 0x02, 0x03])
        let output = AIAgentOutput.image(data)
        let filePath = try output.saveToFile()
        let readOutput = try output.readFromFile(filePath)
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
        let readOutput = try output.readFromFile(filePath)
        if case let .audio(readData) = readOutput {
            #expect(readData == data)
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Unregistered strong typed value returns text output")
    func unregisteredStrongTypedValueReturnsText() throws {
        struct Unregistered: Codable, Sendable { let foo: Int }
        let value = Unregistered(foo: 42)
        let output = AIAgentOutput.strongTypedValue(value)
        let filePath = try output.saveToFile()
        let readOutput = try output.readFromFile(filePath)
        #expect(readOutput.output == "[Unregistered strong typed value: Unregistered]")
    }
}
