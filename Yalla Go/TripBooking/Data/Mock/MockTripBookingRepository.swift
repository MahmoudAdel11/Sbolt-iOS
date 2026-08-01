//
//  MockTripBookingRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// In-memory `TripBookingRepository` that simulates the ride backend while the
/// app has none. An `actor` guarantees safe access. Each step waits a
/// configurable, cancellation-aware delay; `behavior` makes success and the two
/// failure modes deterministic for tests.
actor MockTripBookingRepository: TripBookingRepository {

    enum Behavior {
        case success
        case driverNotFound
        case networkFailure
    }

    private let behavior: Behavior
    private let driver: Driver
    private let searchingDelay: TimeInterval
    private let arrivingDelay: TimeInterval
    private let tripDelay: TimeInterval
    private let cancelDelay: TimeInterval

    init(behavior: Behavior = .success,
         driver: Driver = MockTripBookingRepository.sampleDriver(),
         searchingDelay: TimeInterval = 3,
         arrivingDelay: TimeInterval = 3,
         tripDelay: TimeInterval = 3,
         cancelDelay: TimeInterval = 0.3) {
        self.behavior = behavior
        self.driver = driver
        self.searchingDelay = searchingDelay
        self.arrivingDelay = arrivingDelay
        self.tripDelay = tripDelay
        self.cancelDelay = cancelDelay
    }

    func findDriver() async throws -> Driver {
        try await sleep(searchingDelay)
        switch behavior {
        case .success: return driver
        case .driverNotFound: throw TripBookingError.noDriverFound
        case .networkFailure: throw TripBookingError.networkUnavailable
        }
    }

    func startTrip() async throws {
        try await sleep(arrivingDelay)
    }

    func completeTrip() async throws {
        try await sleep(tripDelay)
    }

    func cancelRequest() async throws {
        try await sleep(cancelDelay)
    }

    // MARK: - Helpers

    /// Cancellation-aware delay. Throws `CancellationError` if the surrounding
    /// task is cancelled while waiting.
    private func sleep(_ seconds: TimeInterval) async throws {
        guard seconds > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    static func sampleDriver() -> Driver {
        Driver(id: "driver-1",
               name: "Ahmed Hassan",
               rating: 4.9,
               vehicleName: "Toyota Corolla",
               vehicleColor: "White",
               plateNumber: "ص م ن 1234",
               profileImage: "person.crop.circle.fill",
               estimatedArrivalMinutes: 4)
    }
}
