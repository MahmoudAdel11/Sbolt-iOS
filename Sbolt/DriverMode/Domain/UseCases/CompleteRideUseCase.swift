//
//  CompleteRideUseCase.swift
//  Yalla Go
//

import Foundation

/// Completes the driver's active ride.
struct CompleteRideUseCase {
    private let repository: DriverRepository

    init(repository: DriverRepository) {
        self.repository = repository
    }

    func execute(rideID: String) async throws -> Trip {
        try await repository.completeRide(id: rideID)
    }
}
