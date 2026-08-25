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
///
/// Also the single interception point for silent token refresh: when the
/// inner client comes back with a 401, this attempts exactly one
/// `tokenRefresher.refreshAccessToken()` and, if it succeeds, retries the
/// original request exactly once with the new token. If refresh fails (no
/// refresh token, or the backend rejects it too — refresh token itself
/// expired/invalid), the original 401 is rethrown unchanged, so the existing
/// per-repository `.sessionExpired` handling downstream is untouched. No
/// second refresh attempt is ever made for the same request — a 401 on the
/// retried request propagates as-is.
///
/// Every repository funnels its requests through this one `send`, so this is
/// the only place a refresh-and-retry needs to live; no per-repository
/// changes are needed for the silent-refresh behavior itself.
final class AuthenticatedAPIClient: APIClient {

    private let inner: any APIClient
    private let tokenProvider: any TokenProvider
    private let tokenRefresher: any TokenRefreshing

    init(
        client: any APIClient,
        tokenProvider: any TokenProvider = NilTokenProvider(),
        tokenRefresher: any TokenRefreshing = NilTokenRefreshing()
    ) {
        self.inner = client
        self.tokenProvider = tokenProvider
        self.tokenRefresher = tokenRefresher
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        do {
            return try await inner.send(await authenticated(endpoint))
        } catch NetworkError.unauthorized {
            guard let newAccessToken = await tokenRefresher.refreshAccessToken() else {
                throw NetworkError.unauthorized
            }
            var retried = endpoint
            retried.headers["Authorization"] = "Bearer \(newAccessToken)"
            return try await inner.send(retried)
        }
    }

    private func authenticated(_ endpoint: Endpoint) async -> Endpoint {
        var authenticated = endpoint
        if let token = await tokenProvider.token() {
            authenticated.headers["Authorization"] = "Bearer \(token)"
        }
        return authenticated
    }
}
