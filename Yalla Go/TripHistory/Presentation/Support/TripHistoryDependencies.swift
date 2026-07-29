//
//  TripHistoryDependencies.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Composition root for the trip-history feature. Wires the mock repository into
/// the use case and vends the view model, so views never build the use case or
/// touch the repository directly.
struct TripHistoryDependencies {

    private let repository: TripRepository

    init(repository: TripRepository = MockTripRepository()) {
        self.repository = repository
    }

    @MainActor
    func makeTripHistoryViewModel() -> TripHistoryViewModel {
        TripHistoryViewModel(getTripHistoryUseCase: GetTripHistoryUseCase(repository: repository))
    }
}
