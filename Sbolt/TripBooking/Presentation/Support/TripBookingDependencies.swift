//
//  TripBookingDependencies.swift
//  Yalla Go
//

import Foundation

/// Composition root for the trip-booking flow. Wires the environment's
/// repository into the use cases (including the polling use case) and vends
/// the view model, so views never build use cases or touch the repository
/// directly.
struct TripBookingDependencies {

    private let repository: any TripBookingRepository
    private let timings: TripFlowTimings
    private let pollInterval: TimeInterval

    init(repository: (any TripBookingRepository)? = nil,
         timings: TripFlowTimings = TripFlowTimings(),
         pollInterval: TimeInterval = RidePollingService.defaultInterval) {
        self.repository = repository ?? AppEnvironment.current.repositoryFactory.makeTripBookingRepository()
        self.timings = timings
        self.pollInterval = pollInterval
    }

    @MainActor
    func makeTripBookingViewModel() -> TripBookingViewModel {
        TripBookingViewModel(
            requestRideUseCase: RequestRideUseCase(repository: repository),
            cancelRideUseCase: CancelRideUseCase(repository: repository),
            pollRideStatusUseCase: PollRideStatusUseCase(repository: repository, interval: pollInterval),
            getActiveRideUseCase: GetActiveRideUseCase(repository: repository),
            timings: timings
        )
    }

    @MainActor
    func makeRatingSubmissionViewModel(rideID: String) -> RatingSubmissionViewModel {
        RatingSubmissionViewModel(
            rideID: rideID,
            submitRatingUseCase: SubmitRatingUseCase(repository: repository)
        )
    }
}
