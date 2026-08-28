//
//  PollRideStatusUseCase.swift
//  Yalla Go
//

import Foundation

/// Streams a ride's status until it reaches a terminal state. Wraps
/// `RidePollingService` so the ViewModel only ever depends on a use case,
/// never on polling mechanics directly.
struct PollRideStatusUseCase {
    private let pollingService: RidePollingService

    init(repository: TripBookingRepository, interval: TimeInterval = RidePollingService.defaultInterval) {
        self.pollingService = RidePollingService(repository: repository, interval: interval)
    }

    func execute(rideID: String) -> AsyncThrowingStream<Trip, Error> {
        pollingService.poll(rideID: rideID)
    }
}
