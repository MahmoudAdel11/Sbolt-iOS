//
//  TripBookingDependencies.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Composition root for the trip-booking flow. Wires the mock repository into
/// the use cases and vends the view model, so views never build use cases or
/// touch the repository directly.
struct TripBookingDependencies {

    private let repository: TripBookingRepository
    private let timings: TripFlowTimings

    init(repository: TripBookingRepository = MockTripBookingRepository(),
         timings: TripFlowTimings = TripFlowTimings()) {
        self.repository = repository
        self.timings = timings
    }

    @MainActor
    func makeTripBookingViewModel() -> TripBookingViewModel {
        TripBookingViewModel(findDriverUseCase: FindDriverUseCase(repository: repository),
                             startTripUseCase: StartTripUseCase(repository: repository),
                             completeTripUseCase: CompleteTripUseCase(repository: repository),
                             cancelTripUseCase: CancelTripUseCase(repository: repository),
                             timings: timings)
    }
}
