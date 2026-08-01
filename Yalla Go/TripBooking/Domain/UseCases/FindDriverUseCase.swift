//
//  FindDriverUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Requests a nearby driver for the trip.
struct FindDriverUseCase {
    private let repository: TripBookingRepository

    init(repository: TripBookingRepository) {
        self.repository = repository
    }

    func execute() async throws -> Driver {
        try await repository.findDriver()
    }
}
