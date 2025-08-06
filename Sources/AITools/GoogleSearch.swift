import Foundation
import AIAgentMacros
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Google search engine
/// https://developers.google.com/custom-search
@AITool
public struct GoogleSearch {
    public enum Error: Swift.Error {
        case invalidRequest
    }
    @AIModelSchema
    public struct Request: Encodable {
        /// Query
        let q: String
        /// Enables or disables Simplified and Traditional Chinese Search.
        /// The default value for this parameter is 0 (zero), meaning that the feature is enabled. Supported values are:
        /// 1: Disabled
        /// 0: Enabled (default)
        let c2coff: String?
        /// Restricts search results to documents originating in a particular country. You may use Boolean operators in the cr parameter's value.
        let cr: String?
        /// Restricts results to URLs based on date. Supported values include:
        /// d[number]: requests results from the specified number of past days.
        /// w[number]: requests results from the specified number of past weeks.
        ///m[number]: requests results from the specified number of past months.
        ///y[number]: requests results from the specified number of past years.
        let dateRestrict: String?
        /// Identifies a phrase that all documents in the search results must contain.
        let exactTerms: String?
        /// Identifies a word or phrase that should not appear in any documents in the search results.
        let excludeTerms: String?
        /// Restricts results to files of a specified extension.
        let fileType: String?
        /// Controls turning on or off the duplicate content filter.
        let filter: String?
        /// Geolocation of end user.
        let gl: String?
        /// Sets the user interface language.
        /// Explicitly setting this parameter improves the performance and the quality of your search results.
        let highRange: String?
        /// Appends the specified query terms to the query, as if they were combined with a logical AND operator.
        let hq: String?
        /// Returns black and white, grayscale, transparent, or color images. Acceptable values are: `color`, `gray`, `mono`, `trans`
        let imgColorType: String?
        /// Returns images of a specific dominant color. Acceptable values are: `black`,`blue`,`brown`,`gray`,`green`,`orange`,`pink`,`purple`,`red`,`teal`,`white`,`yellow`
        let imgDominantColor: String?
        /// Returns images of a specified size. Acceptable values are: `huge`,`icon`,`large`,`medium`,`small`,`xlarge`,`xxlarge`
        let imgSize: String?
        /// Returns images of a type. Acceptable values are: `clipart`,`face`,`lineart`,`stock`,`photo`,`animated`
        let imgType: String?
        /// Specifies the starting value for a search range. Use lowRange and highRange to append an inclusive search range of lowRange...highRange to the query.
        let linkSite: String?
        /// Restricts the search to documents written in a particular language (e.g., lr=lang_ja).
        let lr: String?
        /// Number of search results to return. Valid values are integers between 1 and 10, inclusive.
        let num: Int?
        /// Provides additional search terms to check for in a document, where each document in the search results must contain at least one of the additional search terms.
        let orTerms: String?
        /// Filters based on licensing. Supported values include: cc_publicdomain, cc_attribute, cc_sharealike, cc_noncommercial, cc_nonderived and combinations of these.
        let rights: String?
        /// earch safety level. Acceptable values are: `active`: Enables SafeSearch filtering. `off`: Disables SafeSearch filtering. (default)
        let safe: String?
        /// Specifies the search type: image. If unspecified, results are limited to webpages. Acceptable values are: `image`: custom image search.
        let searchType: String?
        /// Specifies a given site which should always be included or excluded from results (see siteSearchFilter parameter, below).
        let siteSearch: String?
        /// Controls whether to include or exclude results from the site named in the siteSearch parameter.  Acceptable values are: `e`: exclude; `i`: include
        let siteSearchFilter: String?
        /// The sort expression to apply to the results. The sort parameter specifies that the results be sorted according to the specified expression i.e. sort by date. Example: sort=date.
        let sort: String?
        /// The index of the first result to return. The default number of results per page is 10, so &start=11 would start at the top of the second page of results. Note: The JSON API will never return more than 100 results, even if more than 100 documents match the query, so setting the sum of start + num to a number greater than 100 will produce an error. Also note that the maximum value for num is 10.
        let start: Int?

        public init(q: String,
                    c2coff: String? = nil,
                    cr: String? = nil,
                    dateRestrict: String? = nil,
                    exactTerms: String? = nil,
                    excludeTerms: String? = nil,
                    fileType: String? = nil,
                    filter: String? = nil,
                    gl: String? = nil,
                    highRange: String? = nil,
                    hq: String? = nil,
                    imgColorType: String? = nil,
                    imgDominantColor: String? = nil,
                    imgSize: String? = nil,
                    imgType: String? = nil,
                    linkSite: String? = nil,
                    lr: String? = nil,
                    num: Int? = nil,
                    orTerms: String? = nil,
                    rights: String? = nil,
                    safe: String? = nil,
                    searchType: String? = nil,
                    siteSearch: String? = nil,
                    siteSearchFilter: String? = nil,
                    sort: String? = nil,
                    start: Int? = nil) {
            self.q = q
            self.c2coff = c2coff
            self.cr = cr
            self.dateRestrict = dateRestrict
            self.exactTerms = exactTerms
            self.excludeTerms = excludeTerms
            self.fileType = fileType
            self.filter = filter
            self.gl = gl
            self.highRange = highRange
            self.hq = hq
            self.imgColorType = imgColorType
            self.imgDominantColor = imgDominantColor
            self.imgSize = imgSize
            self.imgType = imgType
            self.linkSite = linkSite
            self.lr = lr
            self.num = num
            self.orTerms = orTerms
            self.rights = rights
            self.safe = safe
            self.searchType = searchType
            self.siteSearch = siteSearch
            self.siteSearchFilter = siteSearchFilter
            self.sort = sort
            self.start = start
        }
    }

    @AIModelSchema
    public struct Response: Decodable {
        @AIModelSchema
        public struct Queries: Decodable {
            @AIModelSchema
            public struct QueryRequest: Decodable {
                    let title: String
                    let totalResults: String
                    let searchTerms: String
                    let count: Int
                    let startIndex: Int
                    let inputEncoding: String
                    let outputEncoding: String
                    let safe: String
                    let cx: String
                }
            let request: [QueryRequest]
            let nextPage: [QueryRequest]?
        }
        @AIModelSchema
        public struct SearchInformation: Decodable {
            let searchTime: Double
            let formattedSearchTime: String
            let totalResults: String
            let formattedTotalResults: String
        }
        @AIModelSchema
        public struct SearchItem: Decodable {
            let kind: String
            let title: String
            let htmlTitle: String
            let link: String
            let displayLink: String
            let snippet: String
            let htmlSnippet: String
            let formattedUrl: String
            let htmlFormattedUrl: String
        }
        let queries: Queries
        let searchInformation: SearchInformation
        let items: [SearchItem]
    }
    let cx: String
    let key: String

    var baseUrl: String {
        "https://www.googleapis.com/customsearch/v1?cx=\(cx)&key=\(key)"
    }

    public init(cx: String, key: String) {
        self.cx = cx
        self.key = key
    }

    /// Search internet using Google search engine
    /// - Parameter request: the request for the search
    /// - Returns: the content of the search result
    public func search(request: Request) async throws -> Response {
        guard let url = URL(string: "\(baseUrl)&\(request.parameters)") else {
            throw Error.invalidRequest
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

extension GoogleSearch.Request {
    func propertyName<T, V: Equatable>(of value: T, keyPath: KeyPath<T, V>) -> String? {
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            if let label = child.label,
               let childValue = child.value as? V,
               childValue == value[keyPath: keyPath] {
                return label
            }
        }
        return nil
    }

    var parameters: String {
        [
            \.q.optional,
            \GoogleSearch.Request.c2coff,
             \.cr,
             \.dateRestrict,
             \.exactTerms,
             \.excludeTerms,
             \.fileType,
             \.filter,
             \.gl,
             \.highRange,
             \.hq,
             \.imgColorType,
             \.imgDominantColor,
             \.imgSize,
             \.imgType,
             \.linkSite,
             \.lr,
             \.orTerms,
             \.rights,
             \.safe,
             \.searchType,
             \.siteSearch,
             \.siteSearchFilter,
             \.sort,
             \.num?.string,
             \.start?.string,
        ].reduce(into: [String]()) { result, keyPath in
            if let propertyName = propertyName(of: self, keyPath: keyPath),
               let value = self[keyPath: keyPath] {
                result.append("\(propertyName)=\(value)")
            }
        }.joined(separator: "&")
    }
}

private extension Int {
    var string: String {
        "\(self)"
    }
}

private extension String {
    var optional: String? {
        Optional(self)
    }
}
