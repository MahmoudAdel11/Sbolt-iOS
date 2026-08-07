//
//  CancelRideUseCase.swift
//  Yalla Go
//

import Foundation

/// Cancels an in-progress ride.
struct CancelRideUseCase {
    private let repository: TripBookingRepository

    init(repository: TripBookingRepository) {
        self.repository = repository
    }

    func execute(rideID: String) async throws -> Trip {
        try await repository.cancelRide(id: rideID)
    }
}
