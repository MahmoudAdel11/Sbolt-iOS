//
//  TripBookingViewModel.swift
//  Yalla Go
//

import Foundation
import Combine

/// Owns the ride-booking state machine. Requests a ride, then polls its
/// status (via `PollRideStatusUseCase`, no polling logic lives here) until a
/// terminal state or cancellation. Views only read `phase` and send intents.
@MainActor
final class TripBookingViewModel: ObservableObject {

    @Published private(set) var phase: TripPhase = .idle
    /// Client-side fare estimate for the current/last request. Never sent to
    /// the backend — display only, and always presented as an estimate.
    @Published private(set) var estimatedFare: Double?
    /// `true` once a `.sessionExpired` error is caught. The view observes
    /// this and signs the session out — the ViewModel itself has no access
    /// to `AppSessionStore` (kept environment-agnostic, testable in isolation).
    @Published private(set) var isSessionExpired = false

    private let requestRideUseCase: RequestRideUseCase
    private let cancelRideUseCase: CancelRideUseCase
    private let pollRideStatusUseCase: PollRideStatusUseCase
    private let timings: TripFlowTimings
    private let errorPresenter: TripBookingErrorPresenter

    /// The single owner of the booking flow. Exposed read-only for awaiting in tests.
    private(set) var bookingTask: Task<Void, Never>?
    /// Best-effort cleanup after cancel/completion. Exposed read-only for tests.
    private(set) var cleanupTask: Task<Void, Never>?

    /// Gates the `.completed` → `.idle` auto-reset on the rating prompt's
    /// decision (submit or skip) rather than a fixed delay.
    /// `proceedPastRatingPrompt()` resumes it — but it can be called *before*
    /// `awaitRatingDecision()` has started suspending (e.g. a `Combine`
    /// subscriber reacting to `.completed` synchronously, in the same call
    /// stack as the `phase` assignment below), in which case there's no live
    /// continuation yet to resume. This flag remembers that early call so
    /// `awaitRatingDecision()` returns immediately instead of hanging forever.
    private var earlyRatingAcknowledgment = false
    private var ratingDecisionContinuation: CheckedContinuation<Void, Never>?

    var isIdle: Bool { phase.isIdle }
    var isCancellable: Bool { phase.isCancellable }

    init(requestRideUseCase: RequestRideUseCase,
         cancelRideUseCase: CancelRideUseCase,
         pollRideStatusUseCase: PollRideStatusUseCase,
         timings: TripFlowTimings = TripFlowTimings(),
         errorPresenter: TripBookingErrorPresenter = TripBookingErrorPresenter()) {
        self.requestRideUseCase = requestRideUseCase
        self.cancelRideUseCase = cancelRideUseCase
        self.pollRideStatusUseCase = pollRideStatusUseCase
        self.timings = timings
        self.errorPresenter = errorPresenter
    }

    deinit {
        bookingTask?.cancel()
        cleanupTask?.cancel()
    }

    /// Starts the booking flow. Ignored unless the flow is idle, so there is
    /// never more than one concurrent booking task.
    func confirmTrip(pickup: Coordinate, dropoff: Coordinate, estimatedFare: Double) {
        guard phase.isIdle else { return }
        bookingTask?.cancel()
        self.estimatedFare = estimatedFare
        phase = .requesting // set synchronously so the UI reflects it immediately
        bookingTask = Task { [weak self] in
            await self?.runBooking(pickup: pickup, dropoff: dropoff)
        }
    }

    /// Retries after a failure.
    func retry() {
        guard case .failed = phase else { return }
        phase = .idle
        estimatedFare = nil
    }

    /// Cancels the active ride. Only valid once a ride exists and hasn't
    /// reached a terminal status.
    func cancelTrip() {
        guard case let .active(trip) = phase, isCancellable else { return }
        bookingTask?.cancel()
        cleanupTask = Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.cancelRideUseCase.execute(rideID: trip.id)
            } catch {
                // Best-effort: the poll loop already stopped with this task's
                // cancellation, so there is nothing further to reconcile here —
                // except a dead session, which still needs to be surfaced.
                if case RideError.sessionExpired = error { self.isSessionExpired = true }
            }
            self.phase = .cancelled
            try? await self.sleep(self.timings.resetAfterTerminal)
            if self.phase == .cancelled { self.reset() }
        }
    }

    private func runBooking(pickup: Coordinate, dropoff: Coordinate) async {
        do {
            let trip = try await requestRideUseCase.execute(pickup: pickup, dropoff: dropoff)
            try Task.checkCancellation()
            phase = .active(trip)

            for try await updated in pollRideStatusUseCase.execute(rideID: trip.id) {
                try Task.checkCancellation()
                if updated.status == .completed {
                    phase = .completed(updated)
                    await awaitRatingDecision()
                    try Task.checkCancellation()
                    try await sleep(timings.resetAfterTerminal)
                    try Task.checkCancellation()
                    reset()
                    return
                } else if updated.status == .cancelled {
                    phase = .cancelled
                    try await sleep(timings.resetAfterTerminal)
                    try Task.checkCancellation()
                    reset()
                    return
                } else {
                    phase = .active(updated)
                }
            }
        } catch is CancellationError {
            // Cancellation is owned by `cancelTrip`, which already set the phase.
        } catch {
            phase = .failed(message: errorPresenter.message(for: error))
            if case RideError.sessionExpired = error { isSessionExpired = true }
        }
    }

    /// Called by the rating-prompt UI once the rider has submitted a rating
    /// or explicitly skipped — resumes the `.completed` → `.idle` auto-reset
    /// that was waiting on this decision. Safe to call at any time, including
    /// before the wait has started (see `earlyRatingAcknowledgment`'s doc
    /// comment) or after it's already been consumed (a harmless no-op).
    func proceedPastRatingPrompt() {
        if let continuation = ratingDecisionContinuation {
            continuation.resume()
            ratingDecisionContinuation = nil
        } else {
            earlyRatingAcknowledgment = true
        }
    }

    private func awaitRatingDecision() async {
        if earlyRatingAcknowledgment {
            earlyRatingAcknowledgment = false
            return
        }
        await withCheckedContinuation { continuation in
            ratingDecisionContinuation = continuation
        }
    }

    private func reset() {
        phase = .idle
        estimatedFare = nil
    }

    private func sleep(_ seconds: TimeInterval) async throws {
        guard seconds > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
