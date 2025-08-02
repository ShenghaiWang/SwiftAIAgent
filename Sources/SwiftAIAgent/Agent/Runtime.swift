import Foundation

actor Runtime {
    struct Cache {
        let title: String
        let output: [AIAgentOutput]
    }
    public static let shared = Runtime()
    private init() {}

    private var outputs: [UUID: Cache] = [:]

    func set(output: [AIAgentOutput], for uuid: UUID, title: String) {
        outputs[uuid] = .init(title: title, output: output)
    }

    func output(of uuid: UUID) -> Cache? {
        outputs[uuid]
    }
}
