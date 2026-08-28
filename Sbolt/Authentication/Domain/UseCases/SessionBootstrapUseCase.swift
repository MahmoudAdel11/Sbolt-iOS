//
//  SessionBootstrapUseCase.swift
//  Yalla Go
//

import Foundation

/// Runs at app launch to restore an existing authenticated session.
///
/// Flow:
/// 1. Calls `repository.currentUser()`.
///    - The remote implementation checks Keychain; if no token exists it skips
///      the network call and returns nil immediately.
///    - If a token exists but is expired/invalid (401), the repository clears it
///      and returns nil.
/// 2. Returns the `User` on success, or nil — which routes the app to Login.
struct SessionBootstrapUseCase {

    private let repository: any AuthenticationRepository

    init(repository: any AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async -> User? {
        await repository.currentUser()
    }
}
