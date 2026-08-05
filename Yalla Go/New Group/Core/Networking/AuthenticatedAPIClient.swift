//
//  AuthenticatedAPIClient.swift
//  Yalla Go
//

import Foundation

/// Decorator that wraps any `APIClient` and injects an
/// `Authorization: Bearer <token>` header when a token is available.
///
/// Swap the `TokenProvider` dependency when session state changes — no other
/// layer needs to change. When the provider returns `nil` the request is
/// forwarded as-is (unauthenticated).
final class AuthenticatedAPIClient: APIClient {

    private let inner: any APIClient
    private let tokenProvider: any TokenProvider

    init(client: any APIClient, tokenProvider: any TokenProvider = NilTokenProvider()) {
        self.inner = client
        self.tokenProvider = tokenProvider
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var authenticated = endpoint
        if let token = await tokenProvider.token() {
            authenticated.headers["Authorization"] = "Bearer \(token)"
        }
        return try await inner.send(authenticated)
    }
}
