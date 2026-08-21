//
//  AvailableRidesPollingService.swift
//  Yalla Go
//

import Foundation

/// Polls `GET /rides/available` on a fixed interval since the backend has no
/// push/websocket mechanism — mirrors `RidePollingService`'s exact shape
/// (`Task` + `Task.sleep` wrapped in an `AsyncThrowingStream`), except there
/// is no single terminal status to stop on: the stream only ends when its
/// consumer cancels it (going offline, or leaving the screen).
struct AvailableRidesPollingService {
    /// 5s per the confirmed driver-mode polling decision.
    static let defaultInterval: TimeInterval = 5

    private let repository: DriverRepository
    private let interval: TimeInterval

    init(repository: DriverRepository, interval: TimeInterval = AvailableRidesPollingService.defaultInterval) {
        self.repository = repository
        self.interval = interval
    }

    func poll(near coordinate: Coordinate) -> AsyncThrowingStream<[Trip], Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    while !Task.isCancelled {
                        let rides = try await repository.fetchAvailableRides(near: coordinate)
                        continuation.yield(rides)
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
