//
//  CancelTripUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Cancels the current booking request.
struct CancelTripUseCase {
    private let repository: TripBookingRepository

    init(repository: TripBookingRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.cancelRequest()
    }
}
