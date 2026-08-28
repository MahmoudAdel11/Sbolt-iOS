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
    /// `true` once a `.sessionExpired` error is caught. The view observes
    /// this and signs the session out — the ViewModel itself has no access
    /// to `AppSessionStore` (kept environment-agnostic, testable in isolation).
    @Published private(set) var isSessionExpired = false

    private let requestRideUseCase: RequestRideUseCase
    private let cancelRideUseCase: CancelRideUseCase
    private let pollRideStatusUseCase: PollRideStatusUseCase
    private let getActiveRideUseCase: GetActiveRideUseCase
    private let timings: TripFlowTimings
    private let errorPresenter: TripBookingErrorPresenter
    /// Resolves pickup/dropoff coordinates to place names right before the
    /// request goes out — see `runBooking`. Failure is swallowed at the
    /// `ReverseGeocoding` boundary itself (never throws), so it can't block
    /// ride creation.
    private let reverseGeocoding: ReverseGeocoding

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
         getActiveRideUseCase: GetActiveRideUseCase,
         timings: TripFlowTimings = TripFlowTimings(),
         errorPresenter: TripBookingErrorPresenter = TripBookingErrorPresenter(),
         reverseGeocoding: ReverseGeocoding = CLGeocoderReverseGeocoding()) {
        self.requestRideUseCase = requestRideUseCase
        self.cancelRideUseCase = cancelRideUseCase
        self.pollRideStatusUseCase = pollRideStatusUseCase
        self.getActiveRideUseCase = getActiveRideUseCase
        self.timings = timings
        self.errorPresenter = errorPresenter
        self.reverseGeocoding = reverseGeocoding
    }

    deinit {
        bookingTask?.cancel()
        cleanupTask?.cancel()
    }

    /// Starts the booking flow. Ignored unless the flow is idle, so there is
    /// never more than one concurrent booking task.
    func confirmTrip(pickup: Coordinate, dropoff: Coordinate, tier: RideType) {
        guard phase.isIdle else { return }
        bookingTask?.cancel()
        phase = .requesting // set synchronously so the UI reflects it immediately
        bookingTask = Task { [weak self] in
            await self?.runBooking(pickup: pickup, dropoff: dropoff, tier: tier)
        }
    }

    /// Retries after a failure.
    func retry() {
        guard case .failed = phase else { return }
        phase = .idle
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

    private func runBooking(pickup: Coordinate, dropoff: Coordinate, tier: RideType) async {
        do {
            async let pickupAddress = reverseGeocoding.placeName(for: pickup)
            async let dropoffAddress = reverseGeocoding.placeName(for: dropoff)
            let trip = try await requestRideUseCase.execute(
                pickup: pickup, dropoff: dropoff, tier: tier,
                pickupAddress: await pickupAddress, dropoffAddress: await dropoffAddress
            )
            try Task.checkCancellation()
            phase = .active(trip)
            await trackTrip(trip)
        } catch is CancellationError {
            // Cancellation is owned by `cancelTrip`, which already set the phase.
        } catch {
            phase = .failed(message: errorPresenter.message(for: error))
            if case RideError.sessionExpired = error { isSessionExpired = true }
        }
    }

    /// Polls `trip` until it reaches a terminal status, driving `phase`
    /// throughout. Shared by `runBooking` (right after a fresh request) and
    /// `checkForActiveRide` (resuming tracking of a ride recovered from the
    /// backend, whose `.active` phase was never entered via a request in this
    /// app session).
    private func trackTrip(_ trip: Trip) async {
        do {
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

    /// Recovers a pending/accepted/ongoing ride whose in-memory `phase` was
    /// lost (app relaunch, backgrounding, a fresh `TripBookingViewModel`
    /// instance, etc.) by asking the backend directly. A no-op whenever a
    /// booking flow is already in progress this session (`phase` isn't
    /// `.idle`) — this is specifically for recovering state lost ACROSS a
    /// screen transition or relaunch, never for interrupting a live flow.
    /// Safe to call repeatedly (e.g. on every Home-screen appearance): once
    /// `phase` becomes non-idle, subsequent calls are no-ops until it's idle
    /// again.
    func checkForActiveRide() {
        guard phase.isIdle else { return }
        bookingTask = Task { [weak self] in
            await self?.recoverActiveRideIfAny()
        }
    }

    private func recoverActiveRideIfAny() async {
        do {
            guard let trip = try await getActiveRideUseCase.execute() else { return }
            try Task.checkCancellation()
            // Re-check after the `await` above: a booking flow could have
            // started in the meantime (e.g. the rider tapped Confirm Ride
            // while this check was in flight) - don't clobber it.
            guard phase.isIdle else { return }
            phase = .active(trip)
            await trackTrip(trip)
        } catch is CancellationError {
        } catch {
            // Best-effort: a failed recovery check shouldn't disrupt the
            // normal idle state - the rider can still request a new ride,
            // and the next Home-screen appearance will simply retry.
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
    }

    private func sleep(_ seconds: TimeInterval) async throws {
        guard seconds > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
