//
//  RegisterUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Registers a new account. Validates the submitted details before delegating
/// account creation to the repository.
struct RegisterUseCase {
    private let repository: AuthenticationRepository

    init(repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute(_ details: RegistrationDetails) async throws -> User {
        let username = details.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = details.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneNumber = details.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !username.isEmpty,
              !phoneNumber.isEmpty,
              email.contains("@"),
              details.password.count >= 6 else {
            throw AuthenticationError.invalidInput
        }

        let sanitized = RegistrationDetails(username: username,
                                            email: email,
                                            phoneNumber: phoneNumber,
                                            password: details.password)
        return try await repository.register(sanitized)
    }
}
