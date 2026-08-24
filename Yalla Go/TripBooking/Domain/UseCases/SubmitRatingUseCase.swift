//
//  SubmitRatingUseCase.swift
//  Yalla Go
//

import Foundation

/// Submits a 1-5 star rating for a completed ride.
struct SubmitRatingUseCase {
    private let repository: TripBookingRepository

    init(repository: TripBookingRepository) {
        self.repository = repository
    }

    func execute(rideID: String, score: Int) async throws {
        try await repository.submitRating(rideID: rideID, score: score)
    }
}
