import Common
import GoogleAPITokenManager
import OpenAPIRuntime
import OpenAPIAsyncHTTPClient

protocol GoogleClient {
    static func client<T: AuthorizableClient>(
        serviceAccount: String,
        configuration: Configuration?,
        transportConfiguration: AsyncHTTPClientTransport.Configuration,
        scopes: [String]
    ) throws -> T
    static func client<T: AuthorizableClient>(
        clientId: String,
        clientSecret: String,
        redirectURI: String,
        configuration: Configuration?,
        transportConfiguration: AsyncHTTPClientTransport.Configuration,
        scopes: [String],
        tokenStorage: (any TokenStorage)?
    ) async throws -> T
}

extension GoogleClient {
    static func client<T: AuthorizableClient>(
        serviceAccount: String,
        configuration: Configuration? = nil,
        transportConfiguration: AsyncHTTPClientTransport.Configuration = .init(),
        scopes: [String] = []
    ) throws -> T {
        try T(
            accountServiceFile: serviceAccount,
            configuration: configuration,
            transportConfiguration: transportConfiguration,
            scopes: scopes
        )
    }

    static func client<T: AuthorizableClient>(
        clientId: String,
        clientSecret: String,
        redirectURI: String = "http://localhost",
        configuration: Configuration? = nil,
        transportConfiguration: AsyncHTTPClientTransport.Configuration = .init(),
        scopes: [String] = [],
        tokenStorage: (any TokenStorage)? = InMemoeryTokenStorage(),
    ) async throws -> T {
        let googleOAuth2TokenManager = GoogleOAuth2TokenManager(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            tokenStorage: InMemoeryTokenStorage()
        )
        let oauth = await googleOAuth2TokenManager.buildAuthorizationURL(
            scopes: T.oauthScopes,
            usePKCE: true
        )
        print(oauth.url.absoluteString)
        guard let authCode = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
            !authCode.isEmpty
        else {
            fatalError("❌ No authorization code provided")
        }
        let result = try await googleOAuth2TokenManager.exchangeAuthorizationCode(
            authCode,
            pkceParameters: oauth.pkceParameters
        )
        print(result)
        return try T(
            tokenManager: googleOAuth2TokenManager,
            configuration: configuration,
            transportConfiguration: transportConfiguration,
            scopes: scopes,
            tokenStorage: tokenStorage
        )
    }
}
