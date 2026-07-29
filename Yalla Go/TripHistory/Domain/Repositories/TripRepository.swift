//
//  TripRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Boundary between the domain and whatever provides trip history
/// (a mock today, a real API later).
protocol TripRepository {
    /// Loads the user's completed trips, most recent first.
    func fetchTripHistory() async throws -> [Trip]

    /// Forces a fresh load of the user's completed trips.
    func refreshTripHistory() async throws -> [Trip]
}
