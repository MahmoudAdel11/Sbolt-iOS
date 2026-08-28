//
//  RidePollingService.swift
//  Yalla Go
//

import Foundation

/// Polls `GET /rides/{id}` on a fixed interval since the backend has no
/// push/websocket mechanism. Yields every fetched state and stops on its own
/// once the ride reaches a terminal status (`completed`/`cancelled`) or the
/// stream's consumer cancels it — callers never need to manage a timer.
struct RidePollingService {
    /// 4s balances prompt status updates against request volume — a common
    /// middle ground for ride-hailing polling UX (typically 3-5s).
    static let defaultInterval: TimeInterval = 4

    private let repository: TripBookingRepository
    private let interval: TimeInterval

    init(repository: TripBookingRepository, interval: TimeInterval = RidePollingService.defaultInterval) {
        self.repository = repository
        self.interval = interval
    }

    func poll(rideID: String) -> AsyncThrowingStream<Trip, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    while !Task.isCancelled {
                        let trip = try await repository.getRideDetails(id: rideID)
                        continuation.yield(trip)
                        if trip.status.isTerminal {
                            continuation.finish()
                            return
                        }
                        try Task.checkCancellation()
                        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
