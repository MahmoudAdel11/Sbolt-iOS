//
//  KeychainTokenRefresher.swift
//  Yalla Go
//

import Foundation

/// `TokenRefreshing` that exchanges the Keychain-stored refresh token for a
/// new access token via POST /auth/refresh, persisting the result. Bridges
/// the Keychain + `AuthDTO` (Data layer) into the networking interceptor
/// (Core layer) — the counterpart to `KeychainTokenProvider` on the write side.
///
/// `client` MUST be an unauthenticated/base `APIClient` (e.g. the raw
/// `URLSessionAPIClient`), never the `AuthenticatedAPIClient` this refresher
/// itself backs — sending the refresh call through that would recurse back
/// into this same refresh attempt on any 401.
/// `@unchecked Sendable`: `APIClient`/`TokenStorage` aren't themselves declared
/// `Sendable` (same pre-existing gap `KeychainTokenProvider` has), but every
/// concrete implementation in practice is (value types or `URLSession`-backed)
/// — this opts out of the compiler's per-field check for that same, already
/// accepted reason rather than introducing new warnings.
struct KeychainTokenRefresher: TokenRefreshing, @unchecked Sendable {

    private let client: any APIClient
    private let accessTokenStorage: any TokenStorage
    private let refreshTokenStorage: any TokenStorage

    init(
        client: any APIClient,
        accessTokenStorage: any TokenStorage,
        refreshTokenStorage: any TokenStorage
    ) {
        self.client = client
        self.accessTokenStorage = accessTokenStorage
        self.refreshTokenStorage = refreshTokenStorage
    }

    func refreshAccessToken() async -> String? {
        guard let refreshToken = refreshTokenStorage.retrieve() else { return nil }

        do {
            let body = try JSONEncoder.backend.encode(
                AuthDTO.RefreshRequest(refreshToken: refreshToken)
            )
            let response: AuthDTO.RefreshResponse = try await client.send(
                Endpoint(path: "/auth/refresh", method: .post, body: body)
            )
            accessTokenStorage.save(response.accessToken)
            return response.accessToken
        } catch {
            // Invalid/expired refresh token, or a transient failure — either
            // way there's no new access token to hand back. The caller
            // (AuthenticatedAPIClient) falls back to the original 401.
            return nil
        }
    }
}
