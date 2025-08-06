import Foundation

extension Array: AIModelSchema where Element: AIModelSchema {
    public static var outputSchema: String {
        """
        {
            "type":"array",
            "items":\(Element.outputSchema)
        }
        """
    }
}
