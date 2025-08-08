import Foundation

struct ToolCallingValue: Sendable {
    let name: String
    let args: [String: Data]
}

extension ToolCallingValue {
    /// init from json string in format {"name":"getWeather","args":{"city":"Sydney", "date": { "month":"Jan", "day": "1" }}}
    init?(value: String) {
        guard let data = value.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let argsDict = json["args"] as? [String: Any] else {
            return nil
        }
        var args: [String: Data] = [:]
        for (key, value) in argsDict {
            let serialized: Data?
            if JSONSerialization.isValidJSONObject(value) {
                serialized = try? JSONSerialization.data(withJSONObject: value)
            } else if let str = value as? String {
                serialized = try? JSONEncoder().encode(str)
            } else if let num = value as? Int {
                serialized = try? JSONEncoder().encode(num)
            } else if let num = value as? Double {
                serialized = try? JSONEncoder().encode(num)
            } else {
                serialized = nil
            }
            if let data = serialized {
                args[key] = data
            }
        }
        self.name = name
        self.args = args
    }
}

extension ToolCallingValue {
    var argsString: String {
        let keyValus = args.reduce(into: "") { partialResult, value in
            partialResult.append(contentsOf:
                """
                "\(value.key)":\(String(data: value.value, encoding: .utf8) ?? "")
                """
            )
        }
        return "{\(keyValus)}"
    }
}
