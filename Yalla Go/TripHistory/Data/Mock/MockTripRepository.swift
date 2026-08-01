//
//  MockTripRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// In-memory `TripRepository` that simulates a backend while the app has none.
/// An `actor` guarantees safe access; `behavior` and the injected trip list make
/// success, failure, and empty-history scenarios deterministic for tests.
actor MockTripRepository: TripRepository {

    enum Behavior {
        case success
        case failure
    }

    private let trips: [Trip]
    private let behavior: Behavior
    private let artificialDelay: TimeInterval

    init(trips: [Trip] = MockTripRepository.sampleTrips(),
         behavior: Behavior = .success,
         artificialDelay: TimeInterval = 0.5) {
        self.trips = trips
        self.behavior = behavior
        self.artificialDelay = artificialDelay
    }

    func fetchTripHistory() async throws -> [Trip] {
        await simulateNetworkDelay()
        guard behavior == .success else { throw TripHistoryError.historyUnavailable }
        return trips
    }

    func refreshTripHistory() async throws -> [Trip] {
        await simulateNetworkDelay()
        guard behavior == .success else { throw TripHistoryError.refreshFailed }
        return trips
    }

    // MARK: - Helpers

    private func simulateNetworkDelay() async {
        guard artificialDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(artificialDelay * 1_000_000_000))
    }

    /// Deterministic completed trips (most recent first) for previews and tests.
    static func sampleTrips() -> [Trip] {
        [
            Trip(id: "trip-1",
                 pickupLocationName: "Cairo Festival City",
                 destinationLocationName: "Cairo International Airport",
                 pickupCoordinate: Coordinate(latitude: 30.0287, longitude: 31.4090),
                 destinationCoordinate: Coordinate(latitude: 30.1219, longitude: 31.4056),
                 price: 185.50,
                 tripType: .black,
                 distance: 14_200,
                 duration: 24 * 60,
                 completedAt: Date(timeIntervalSince1970: 1_720_000_000),
                 status: .completed),
            Trip(id: "trip-2",
                 pickupLocationName: "Zamalek",
                 destinationLocationName: "Downtown Cairo",
                 pickupCoordinate: Coordinate(latitude: 30.0614, longitude: 31.2197),
                 destinationCoordinate: Coordinate(latitude: 30.0444, longitude: 31.2357),
                 price: 42.00,
                 tripType: .uberX,
                 distance: 3_100,
                 duration: 11 * 60,
                 completedAt: Date(timeIntervalSince1970: 1_719_800_000),
                 status: .completed),
            Trip(id: "trip-3",
                 pickupLocationName: "New Cairo",
                 destinationLocationName: "Maadi",
                 pickupCoordinate: Coordinate(latitude: 30.0080, longitude: 31.4913),
                 destinationCoordinate: Coordinate(latitude: 29.9603, longitude: 31.2569),
                 price: 96.75,
                 tripType: .uberXL,
                 distance: 21_500,
                 duration: 33 * 60,
                 completedAt: Date(timeIntervalSince1970: 1_719_600_000),
                 status: .completed)
        ]
    }
}
