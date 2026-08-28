//
//  GetCurrentUserUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Retrieves the currently signed-in user, if any.
struct GetCurrentUserUseCase {
    private let repository: AuthenticationRepository

    init(repository: AuthenticationRepository) {
        self.repository = repository
    }

    func execute() async -> User? {
        await repository.currentUser()
    }
}
