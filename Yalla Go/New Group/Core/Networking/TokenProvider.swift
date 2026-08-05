//
//  TokenProvider.swift
//  Yalla Go
//

import Foundation

/// Supplies the current Bearer access token for authenticated API requests.
///
/// Inject a concrete implementation (e.g. `KeychainTokenProvider`) once the
/// login flow is wired. Use `NilTokenProvider` (the default) before
/// authentication is implemented — it emits no token and produces no header.
protocol TokenProvider: Sendable {
    /// Returns the stored access token, or `nil` if no session exists.
    func token() async -> String?
}

// MARK: - No-op default

/// Token provider used before authentication is implemented.
/// Produces no Authorization header — all requests remain unauthenticated.
struct NilTokenProvider: TokenProvider {
    func token() async -> String? { nil }
}
