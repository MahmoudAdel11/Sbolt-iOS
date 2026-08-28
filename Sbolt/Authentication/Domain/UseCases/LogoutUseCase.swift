//
//  LogoutUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Ends the current authenticated session.
struct LogoutUseCase {
    private let repository: AuthenticationRepository

    init(repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.logout()
    }
}
