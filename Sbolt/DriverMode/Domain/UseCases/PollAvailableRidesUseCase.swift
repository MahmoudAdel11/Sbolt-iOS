//
//  PollAvailableRidesUseCase.swift
//  Yalla Go
//

import Foundation

/// Streams the list of currently-available rides near a coordinate, on a
/// fixed interval, until the caller cancels. Wraps `AvailableRidesPollingService`
/// so the ViewModel only ever depends on a use case, never on polling mechanics.
struct PollAvailableRidesUseCase {
    private let pollingService: AvailableRidesPollingService

    init(repository: DriverRepository, interval: TimeInterval = AvailableRidesPollingService.defaultInterval) {
        self.pollingService = AvailableRidesPollingService(repository: repository, interval: interval)
    }

    func execute(near coordinate: Coordinate) -> AsyncThrowingStream<[Trip], Error> {
        pollingService.poll(near: coordinate)
    }
}
