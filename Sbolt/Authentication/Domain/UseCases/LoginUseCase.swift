//
//  LoginUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Signs a user in. Performs client-side input validation before delegating
/// the actual authentication to the repository.
struct LoginUseCase {
    private let repository: AuthenticationRepository

    init(repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) async throws -> User {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthenticationError.invalidCredentials
        }
        return try await repository.login(email: email, password: password)
    }
}
