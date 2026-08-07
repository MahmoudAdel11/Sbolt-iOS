//
//  GetTripHistoryUseCase.swift
//  Yalla Go
//

import Foundation

/// Retrieves one page of the user's trip history, optionally forcing a
/// refresh of the first page.
struct GetTripHistoryUseCase {
    static let defaultPageSize = 20

    private let repository: TripRepository
    private let pageSize: Int

    init(repository: TripRepository, pageSize: Int = GetTripHistoryUseCase.defaultPageSize) {
        self.repository = repository
        self.pageSize = pageSize
    }

    func execute(offset: Int = 0, refresh: Bool = false) async throws -> TripHistoryPage {
        refresh
            ? try await repository.refreshTripHistory(limit: pageSize)
            : try await repository.fetchTripHistory(offset: offset, limit: pageSize)
    }
}
