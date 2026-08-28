//
//  RatingSubmissionViewModel.swift
//  Yalla Go
//

import Foundation

/// Drives the post-ride rating prompt. Deliberately minimal — one action
/// (submit), no retry/backoff logic — since a failed submission is
/// non-blocking by design (see RideError.ratingFailed) and the view simply
/// lets the rider skip instead.
@MainActor
final class RatingSubmissionViewModel: ObservableObject {

    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSubmit = false

    private let rideID: String
    private let submitRatingUseCase: SubmitRatingUseCase
    private let errorPresenter: TripBookingErrorPresenter

    init(rideID: String, submitRatingUseCase: SubmitRatingUseCase,
         errorPresenter: TripBookingErrorPresenter = TripBookingErrorPresenter()) {
        self.rideID = rideID
        self.submitRatingUseCase = submitRatingUseCase
        self.errorPresenter = errorPresenter
    }

    func submit(score: Int) {
        guard !isSubmitting, (1...5).contains(score) else { return }
        isSubmitting = true
        errorMessage = nil
        Task { [weak self] in
            guard let self else { return }
            defer { self.isSubmitting = false }
            do {
                try await self.submitRatingUseCase.execute(rideID: self.rideID, score: score)
                self.didSubmit = true
            } catch is CancellationError {
            } catch {
                self.errorMessage = self.errorPresenter.message(for: error)
            }
        }
    }
}
