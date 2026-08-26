//
//  DriverRepository.swift
//  Yalla Go
//

import Foundation

/// Boundary for the driver-side backend surface: going online/offline,
/// browsing nearby requested rides, and accepting/completing one. Reuses the
/// shared `Trip`/`User`/`Coordinate` domain models — a driver's accepted ride
/// is the exact same `Trip` a rider sees, just reached from the other side.
protocol DriverRepository {
    /// Sets online/offline status. Returns the updated `User` (with a fresh
    /// `driverProfile`) so callers never have to assume the write succeeded.
    func setOnlineStatus(_ isOnline: Bool) async throws -> User
    /// Fetches ride requests currently awaiting a driver, near `coordinate`.
    func fetchAvailableRides(near coordinate: Coordinate) async throws -> [Trip]
    /// Accepts a ride. Throws `.rideNoLongerAvailable` if another driver won the race.
    func acceptRide(id: String) async throws -> Trip
    /// Marks the driver's accepted ride as underway. Purely advisory — never a
    /// prerequisite for `completeRide`, which accepts both `.accepted` and
    /// `.ongoing` starting statuses permanently.
    func startRide(id: String) async throws -> Trip
    /// Completes the driver's active ride.
    func completeRide(id: String) async throws -> Trip
}
