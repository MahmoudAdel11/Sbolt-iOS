//
//  GetActiveRideUseCase.swift
//  Yalla Go
//

import Foundation

/// Fetches the rider's current non-terminal ride, if any — the recovery
/// path for a pending ride whose in-memory state was lost (app relaunch,
/// backgrounding, etc.).
struct GetActiveRideUseCase {
    private let repository: TripBookingRepository

    init(repository: TripBookingRepository) {
        self.repository = repository
    }

    func execute() async throws -> Trip? {
        try await repository.getActiveRide()
    }
}
