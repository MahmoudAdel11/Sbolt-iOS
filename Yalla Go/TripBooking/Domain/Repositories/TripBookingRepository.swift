//
//  TripBookingRepository.swift
//  Yalla Go
//

import Foundation

/// Boundary for the ride-booking backend (mock today, a real API later).
///
/// Shaped around the backend's actual REST lifecycle: a rider requests a
/// ride, then polls for its current state until a driver accepts and the
/// ride completes (or is cancelled) — there is no "find driver" call, no
/// "start trip" call, and no push/websocket mechanism, so status changes are
/// only observable by re-fetching ride details.
protocol TripBookingRepository {
    /// Requests a new ride for the given pickup/dropoff coordinates.
    func requestRide(pickup: Coordinate, dropoff: Coordinate) async throws -> Trip
    /// Cancels an in-progress ride. Valid from any non-terminal status.
    func cancelRide(id: String) async throws -> Trip
    /// Fetches the current state of a ride — the polling target.
    func getRideDetails(id: String) async throws -> Trip
    /// Submits a 1-5 star rating for a completed ride. Optional from the
    /// rider's perspective — callers should treat failure as non-blocking.
    func submitRating(rideID: String, score: Int) async throws
}
