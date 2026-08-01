//
//  CompleteTripUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Waits for the in-progress trip to reach its destination.
struct CompleteTripUseCase {
    private let repository: TripBookingRepository

    init(repository: TripBookingRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.completeTrip()
    }
}
