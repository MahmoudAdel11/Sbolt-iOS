//
//  TokenStorage.swift
//  Yalla Go
//

import Foundation
import Security

// MARK: - Protocol

/// Persists a single token (access or refresh) across app launches.
/// No token-type knowledge lives here — callers decide what to store, via
/// the `account` a `KeychainTokenStorage` instance is created with.
protocol TokenStorage {
    func save(_ token: String)
    func retrieve() -> String?
    func delete()
}

/// The two distinct Keychain slots this app stores tokens under. Shared here
/// so every call site (RepositoryFactory, AppSessionStore, KeychainTokenProvider)
/// uses the same strings instead of re-typing them.
enum TokenAccount {
    static let access = "accessToken"
    static let refresh = "refreshToken"
}

// MARK: - Keychain implementation

/// Stores a token in the system Keychain using the Security framework, under
/// the given `account` — one instance per token kind (see `TokenAccount`).
/// No third-party dependency — kSecClassGenericPassword is process-safe and
/// survives app reinstalls until the user signs out or the OS removes the item.
struct KeychainTokenStorage: TokenStorage {

    private let service = "com.yallago.auth"
    private let account: String

    init(account: String = TokenAccount.access) {
        self.account = account
    }

    func save(_ token: String) {
        delete()  // Remove any stale item before inserting.
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      account,
            kSecValueData as String:        Data(token.utf8),
            kSecAttrAccessible as String:   kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func retrieve() -> String? {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      account,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
