//
//  UpdateProfileUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Saves changes to the editable profile fields.
struct UpdateProfileUseCase {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func execute(_ update: ProfileUpdate) async throws -> User {
        try await repository.updateProfile(update)
    }
}
