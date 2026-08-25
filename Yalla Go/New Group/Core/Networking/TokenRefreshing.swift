//
//  TokenRefreshing.swift
//  Yalla Go
//

import Foundation

/// Attempts to silently exchange the stored refresh token for a new access
/// token when a request comes back 401 — the counterpart to `TokenProvider`
/// on the write side. Kept as its own Core-layer protocol (rather than
/// widening `TokenProvider`) so the networking layer stays ignorant of
/// Keychain/DTO details; a concrete implementation (e.g.
/// `KeychainTokenRefresher`) bridges those in from the Data layer.
protocol TokenRefreshing: Sendable {
    /// Returns a new access token on success (already persisted by the
    /// implementation), or `nil` if refresh isn't possible or was rejected
    /// (no refresh token stored, or the backend rejected it as expired/invalid).
    func refreshAccessToken() async -> String?
}

// MARK: - No-op default

/// Used before the refresh flow is wired, or wherever silent refresh isn't
/// wanted — every 401 falls straight through to the caller, unchanged from
/// today's behavior.
struct NilTokenRefreshing: TokenRefreshing {
    func refreshAccessToken() async -> String? { nil }
}
