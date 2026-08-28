//
//  KeychainTokenProvider.swift
//  Yalla Go
//

import Foundation

/// `TokenProvider` that reads the access token from `KeychainTokenStorage`.
/// Bridges the Keychain (Data layer) into the networking interceptor (Core layer)
/// without leaking Keychain details into the networking layer.
///
/// `@unchecked Sendable`: `TokenStorage` isn't itself declared `Sendable` —
/// making it so would just push the same per-conformer check onto every
/// `TokenStorage` implementation (including test doubles with mutable,
/// non-thread-safe state), rather than fixing anything. Every production
/// implementation in practice is safe (e.g. `KeychainTokenStorage` holds only
/// immutable `let` properties), so this opts out of the compiler's per-field
/// check here — same reasoning as `KeychainTokenRefresher`.
struct KeychainTokenProvider: TokenProvider, @unchecked Sendable {

    private let storage: any TokenStorage

    init(storage: any TokenStorage = KeychainTokenStorage()) {
        self.storage = storage
    }

    func token() async -> String? {
        storage.retrieve()
    }
}
