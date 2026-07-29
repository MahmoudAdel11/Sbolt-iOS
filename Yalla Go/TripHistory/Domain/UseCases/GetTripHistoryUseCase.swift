//
//  GetTripHistoryUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Retrieves the user's trip history, optionally forcing a refresh.
struct GetTripHistoryUseCase {
    private let repository: TripRepository

    init(repository: TripRepository) {
        self.repository = repository
    }

    func execute(refresh: Bool = false) async throws -> [Trip] {
        refresh
            ? try await repository.refreshTripHistory()
            : try await repository.fetchTripHistory()
    }
}
