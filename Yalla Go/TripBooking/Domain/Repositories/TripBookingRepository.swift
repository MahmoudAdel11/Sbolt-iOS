//
//  TripBookingRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Boundary for the ride-booking backend (mock today, a real API later).
/// Each async call simulates the wait for that step and honours task
/// cancellation. Consolidates the driver-matching responsibilities
/// (find/cancel) and the trip lifecycle (start/complete) behind one seam.
protocol TripBookingRepository {
    /// Searches for and returns a matched driver, or throws if none is found.
    func findDriver() async throws -> Driver
    /// Waits until the matched driver reaches the pickup and the trip begins.
    func startTrip() async throws
    /// Waits until the in-progress trip reaches its destination.
    func completeTrip() async throws
    /// Cancels the current request (best-effort).
    func cancelRequest() async throws
}
