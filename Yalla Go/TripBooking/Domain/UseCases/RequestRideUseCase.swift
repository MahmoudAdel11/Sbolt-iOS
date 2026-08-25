//
//  RequestRideUseCase.swift
//  Yalla Go
//

import Foundation

/// Requests a new ride for the given pickup/dropoff coordinates.
struct RequestRideUseCase {
    private let repository: TripBookingRepository

    init(repository: TripBookingRepository) {
        self.repository = repository
    }

    func execute(pickup: Coordinate, dropoff: Coordinate, tier: RideType) async throws -> Trip {
        try await repository.requestRide(pickup: pickup, dropoff: dropoff, tier: tier)
    }
}
