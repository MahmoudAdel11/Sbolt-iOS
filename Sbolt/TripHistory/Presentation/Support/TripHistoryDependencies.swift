//
//  TripHistoryDependencies.swift
//  Yalla Go
//

import Foundation

/// Composition root for the trip-history feature. Wires the environment's
/// repository into the use case and vends the view model, so views never
/// build the use case or touch the repository directly.
struct TripHistoryDependencies {

    private let repository: any TripRepository
    private let view: RideView

    init(repository: (any TripRepository)? = nil, view: RideView = .rider) {
        self.repository = repository ?? AppEnvironment.current.repositoryFactory.makeTripRepository()
        self.view = view
    }

    @MainActor
    func makeTripHistoryViewModel() -> TripHistoryViewModel {
        TripHistoryViewModel(getTripHistoryUseCase: GetTripHistoryUseCase(repository: repository, view: view))
    }
}
