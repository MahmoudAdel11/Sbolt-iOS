//
//  TripRepository.swift
//  Yalla Go
//

import Foundation

/// Boundary between the domain and whatever provides trip history
/// (a mock today, a real API later). Paginated: the backend only ever
/// returns `{items, has_more}`, no total count or cursor.
protocol TripRepository {
    /// Loads one page of history, most recent first, for the given side of
    /// the ride (`.rider` or `.driver` — mirrors the backend's `as` param).
    func fetchTripHistory(offset: Int, limit: Int, view: RideView) async throws -> TripHistoryPage

    /// Forces a fresh load of the first page.
    func refreshTripHistory(limit: Int, view: RideView) async throws -> TripHistoryPage
}
