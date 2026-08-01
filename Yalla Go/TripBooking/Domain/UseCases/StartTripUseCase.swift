//
//  StartTripUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Waits for the driver to arrive and the trip to start.
struct StartTripUseCase {
    private let repository: TripBookingRepository

    init(repository: TripBookingRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.startTrip()
    }
}
