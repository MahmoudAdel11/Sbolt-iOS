//
//  TripRepository.swift
//  Yalla Go
//

import Foundation

/// Boundary between the domain and whatever provides trip history
/// (a mock today, a real API later). Paginated: the backend only ever
/// returns `{items, has_more}`, no total count or cursor.
protocol TripRepository {
    /// Loads one page of the user's trip history, most recent first.
    func fetchTripHistory(offset: Int, limit: Int) async throws -> TripHistoryPage

    /// Forces a fresh load of the first page.
    func refreshTripHistory(limit: Int) async throws -> TripHistoryPage
}
