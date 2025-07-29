import Foundation
import SwiftSyntax

extension FunctionDeclSyntax {
    var docComments: [String] {
        leadingTrivia.compactMap {
            if case let .docLineComment(text) = $0 {
                return text.replacingOccurrences(of: "///", with: "").trimmingCharacters(in: .whitespaces)
            }
            return nil
        }
    }
    
    var parsedDoc: (description: String?, parameters: [String: String], returns: String?) {
        var description: String?
        var parameters: [String: String] = [:]
        var returns: String?
        
        for line in docComments {
            if line.hasPrefix("- parameter") {
                // Example: "- parameter city: The name of the city"
                let paramLine = line.dropFirst("- parameter".count).trimmingCharacters(in: .whitespaces)
                if let colonIndex = paramLine.firstIndex(of: ":") {
                    let name = paramLine[..<colonIndex].trimmingCharacters(in: .whitespaces)
                    let desc = paramLine[paramLine.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
                    parameters[String(name)] = desc
                }
            } else if line.hasPrefix("- returns:") {
                returns = line.dropFirst("- returns:".count).trimmingCharacters(in: .whitespaces)
            } else if description == nil && !line.isEmpty {
                description = line
            }
        }
        return (description, parameters, returns)
    }
    
    var toolSchema: String? {
        """
        {
            "name": "\(name.text)",
            "description": "\(1)",
            "parametersJsonSchema": {
                "properties": {
                    
                }
            },
            "type": "object",
            "required": ["city"],
        }
        """
    }
}
/*
{
          "name": "getWeather",
          "responseJsonSchema": {
            "properties": {
              "city": {
                "type": "string",
                "description": "the name of the city"
              }
            },
            "type": "object",
            "required": ["city"],
            "description": "The location parameter for getWeather function"
          },
          "parametersJsonSchema": {
            "properties": {
              "city": {
                "description": "the name of the city",
                "type": "string"
              }
            },
            "type": "object",
            "required": ["city"],
            "description": "The location parameter for getWeather function"
          },
          "description": "Find the weather in the specified city"
        }
*/
