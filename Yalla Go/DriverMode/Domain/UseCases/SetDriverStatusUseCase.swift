//
//  SetDriverStatusUseCase.swift
//  Yalla Go
//

import Foundation

/// Sets the driver's online/offline status.
struct SetDriverStatusUseCase {
    private let repository: DriverRepository

    init(repository: DriverRepository) {
        self.repository = repository
    }

    func execute(isOnline: Bool) async throws -> User {
        try await repository.setOnlineStatus(isOnline)
    }
}
