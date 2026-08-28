//
//  AcceptRideUseCase.swift
//  Yalla Go
//

import Foundation

/// Accepts an available ride. Throws `DriverError.rideNoLongerAvailable` if
/// another driver accepted it first (the backend's 409 race-condition case).
struct AcceptRideUseCase {
    private let repository: DriverRepository

    init(repository: DriverRepository) {
        self.repository = repository
    }

    func execute(rideID: String) async throws -> Trip {
        try await repository.acceptRide(id: rideID)
    }
}
