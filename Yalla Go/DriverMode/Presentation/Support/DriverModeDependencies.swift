//
//  DriverModeDependencies.swift
//  Yalla Go
//

import Foundation

/// Composition root for the driver-mode feature. Wires the environment's
/// repository into the use cases (including the polling use case) and vends
/// the view model, so views never build use cases or touch the repository
/// directly.
struct DriverModeDependencies {

    private let repository: any DriverRepository
    private let pollInterval: TimeInterval

    init(repository: (any DriverRepository)? = nil,
         pollInterval: TimeInterval = AvailableRidesPollingService.defaultInterval) {
        self.repository = repository ?? AppEnvironment.current.repositoryFactory.makeDriverRepository()
        self.pollInterval = pollInterval
    }

    @MainActor
    func makeDriverModeViewModel() -> DriverModeViewModel {
        DriverModeViewModel(
            setDriverStatusUseCase: SetDriverStatusUseCase(repository: repository),
            pollAvailableRidesUseCase: PollAvailableRidesUseCase(repository: repository, interval: pollInterval),
            acceptRideUseCase: AcceptRideUseCase(repository: repository),
            completeRideUseCase: CompleteRideUseCase(repository: repository)
        )
    }
}
