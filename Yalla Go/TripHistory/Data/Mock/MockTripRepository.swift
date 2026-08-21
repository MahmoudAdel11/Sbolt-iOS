//
//  MockTripRepository.swift
//  Yalla Go
//

import Foundation

/// In-memory `TripRepository` that simulates a backend while the app has none.
/// An `actor` guarantees safe access; `behavior` and the injected trip list make
/// success, failure, and empty-history scenarios deterministic for tests.
/// Pagination is simulated by slicing the injected `trips` array the same way
/// the real backend slices its query — no special-casing for "the mock".
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

    /// `view` doesn't filter the mock's injected trip list — the same
    /// deterministic list stands in for whichever side is requested since
    /// this repository has no separate rider/driver datasets to distinguish.
    func fetchTripHistory(offset: Int, limit: Int, view: RideView) async throws -> TripHistoryPage {
        await simulateNetworkDelay()
        guard behavior == .success else { throw TripHistoryError.historyUnavailable }
        return page(offset: offset, limit: limit)
    }

    func refreshTripHistory(limit: Int, view: RideView) async throws -> TripHistoryPage {
        await simulateNetworkDelay()
        guard behavior == .success else { throw TripHistoryError.refreshFailed }
        return page(offset: 0, limit: limit)
    }

    // MARK: - Helpers

    private func page(offset: Int, limit: Int) -> TripHistoryPage {
        guard offset < trips.count else { return TripHistoryPage(trips: [], hasMore: false) }
        let end = min(offset + limit, trips.count)
        return TripHistoryPage(trips: Array(trips[offset..<end]), hasMore: end < trips.count)
    }

    private func simulateNetworkDelay() async {
        guard artificialDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(artificialDelay * 1_000_000_000))
    }

    /// Deterministic rides (most recent first) covering all 5 lifecycle
    /// states, for previews and tests. Fewer than a default page (20), so
    /// `hasMore` is `false` for callers using this directly.
    static func sampleTrips() -> [Trip] {
        [
            Trip(id: "trip-1", riderID: "rider-1", driverID: nil,
                 status: .requested,
                 pickupCoordinate: Coordinate(latitude: 30.0287, longitude: 31.4090),
                 destinationCoordinate: Coordinate(latitude: 30.1219, longitude: 31.4056),
                 requestedAt: Date(timeIntervalSince1970: 1_720_100_000),
                 acceptedAt: nil, completedAt: nil, cancelledAt: nil),
            Trip(id: "trip-2", riderID: "rider-1", driverID: "driver-2",
                 status: .ongoing,
                 pickupCoordinate: Coordinate(latitude: 30.0614, longitude: 31.2197),
                 destinationCoordinate: Coordinate(latitude: 30.0444, longitude: 31.2357),
                 requestedAt: Date(timeIntervalSince1970: 1_720_000_500),
                 acceptedAt: Date(timeIntervalSince1970: 1_720_000_600), completedAt: nil, cancelledAt: nil),
            Trip(id: "trip-3", riderID: "rider-1", driverID: "driver-3",
                 status: .completed,
                 pickupCoordinate: Coordinate(latitude: 30.0080, longitude: 31.4913),
                 destinationCoordinate: Coordinate(latitude: 29.9603, longitude: 31.2569),
                 requestedAt: Date(timeIntervalSince1970: 1_720_000_000),
                 acceptedAt: Date(timeIntervalSince1970: 1_720_000_100),
                 completedAt: Date(timeIntervalSince1970: 1_720_002_000), cancelledAt: nil),
            Trip(id: "trip-4", riderID: "rider-1", driverID: nil,
                 status: .cancelled,
                 pickupCoordinate: Coordinate(latitude: 30.0444, longitude: 31.2357),
                 destinationCoordinate: Coordinate(latitude: 30.0614, longitude: 31.2197),
                 requestedAt: Date(timeIntervalSince1970: 1_719_800_000),
                 acceptedAt: nil, completedAt: nil,
                 cancelledAt: Date(timeIntervalSince1970: 1_719_800_120))
        ]
    }

    /// `count` deterministic, distinctly-ID'd trips (most recent first) for
    /// exercising pagination across page boundaries.
    static func manyTrips(count: Int) -> [Trip] {
        (0..<count).map { index in
            Trip(id: "trip-\(index)", riderID: "rider-1", driverID: nil,
                 status: .completed,
                 pickupCoordinate: Coordinate(latitude: 30.0, longitude: 31.0),
                 destinationCoordinate: Coordinate(latitude: 30.1, longitude: 31.1),
                 requestedAt: Date(timeIntervalSince1970: 1_720_000_000 - Double(index) * 60),
                 acceptedAt: nil,
                 completedAt: Date(timeIntervalSince1970: 1_720_000_500 - Double(index) * 60),
                 cancelledAt: nil)
        }
    }
}
