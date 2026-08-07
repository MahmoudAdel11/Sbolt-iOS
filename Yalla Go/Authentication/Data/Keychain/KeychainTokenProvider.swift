//
//  KeychainTokenProvider.swift
//  Yalla Go
//

import Foundation

/// `TokenProvider` that reads the access token from `KeychainTokenStorage`.
/// Bridges the Keychain (Data layer) into the networking interceptor (Core layer)
/// without leaking Keychain details into the networking layer.
struct KeychainTokenProvider: TokenProvider {

    private let storage: any TokenStorage

    init(storage: any TokenStorage = KeychainTokenStorage()) {
        self.storage = storage
    }

    func token() async -> String? {
        storage.retrieve()
    }
}
