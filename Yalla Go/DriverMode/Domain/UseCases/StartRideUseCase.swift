//
//  StartRideUseCase.swift
//  Yalla Go
//

import Foundation

/// Marks the driver's accepted ride as underway. Purely advisory — never
/// required before `CompleteRideUseCase`, which accepts both `.accepted`
/// and `.ongoing` permanently.
struct StartRideUseCase {
    private let repository: DriverRepository

    init(repository: DriverRepository) {
        self.repository = repository
    }

    func execute(rideID: String) async throws -> Trip {
        try await repository.startRide(id: rideID)
    }
}
