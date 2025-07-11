import Foundation

extension Array: AIModelOutput where Element: AIModelOutput {
    public static var outputSchema: String {
        """
        {
            "type":"array",
            "items":\(Element.outputSchema)
        }
        """
    }
}
