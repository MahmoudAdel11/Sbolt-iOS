//
//  TripBookingViewModel.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation
import Combine

/// Owns the ride-booking state machine. Runs the whole flow inside a single
/// owned `Task`, sets `phase` on the main actor, and checks cancellation after
/// every suspension so a cancelled/superseded step can never overwrite newer
/// state. Views only read `phase` and send intents.
@MainActor
final class TripBookingViewModel: ObservableObject {

    @Published private(set) var phase: TripPhase = .idle

    private let findDriverUseCase: FindDriverUseCase
    private let startTripUseCase: StartTripUseCase
    private let completeTripUseCase: CompleteTripUseCase
    private let cancelTripUseCase: CancelTripUseCase
    private let timings: TripFlowTimings
    private let errorPresenter: TripBookingErrorPresenter

    /// The single owner of the booking flow. Exposed read-only for awaiting in tests.
    private(set) var bookingTask: Task<Void, Never>?
    /// Best-effort cleanup after a cancellation. Exposed read-only for tests.
    private(set) var cleanupTask: Task<Void, Never>?

    var isIdle: Bool { phase.isIdle }
    var isCancellable: Bool { phase.isCancellable }

    init(findDriverUseCase: FindDriverUseCase,
         startTripUseCase: StartTripUseCase,
         completeTripUseCase: CompleteTripUseCase,
         cancelTripUseCase: CancelTripUseCase,
         timings: TripFlowTimings = TripFlowTimings(),
         errorPresenter: TripBookingErrorPresenter = TripBookingErrorPresenter()) {
        self.findDriverUseCase = findDriverUseCase
        self.startTripUseCase = startTripUseCase
        self.completeTripUseCase = completeTripUseCase
        self.cancelTripUseCase = cancelTripUseCase
        self.timings = timings
        self.errorPresenter = errorPresenter
    }

    deinit {
        bookingTask?.cancel()
        cleanupTask?.cancel()
    }

    /// Starts the booking flow. Ignored unless the flow is idle, so there is
    /// never more than one concurrent booking task.
    func confirmTrip() {
        guard phase.isIdle else { return }
        bookingTask?.cancel()
        phase = .searching // set synchronously so the UI/cancel reflect it immediately
        bookingTask = Task { [weak self] in
            await self?.runBooking()
        }
    }

    /// Retries after a failure.
    func retry() {
        guard case .failed = phase else { return }
        phase = .idle
        confirmTrip()
    }

    /// Cancels while searching or while the driver is arriving: stops the
    /// booking task, resets state, and returns to idle after a short beat.
    func cancelTrip() {
        guard phase.isCancellable else { return }
        bookingTask?.cancel()
        phase = .cancelled
        cleanupTask = Task { [weak self] in
            guard let self else { return }
            try? await self.cancelTripUseCase.execute()
            try? await self.sleep(self.timings.resetAfterCancel)
            if self.phase == .cancelled { self.phase = .idle }
        }
    }

    private func runBooking() async {
        do {
            let driver = try await findDriverUseCase.execute()
            try Task.checkCancellation()
            phase = .driverFound(driver)

            try await sleep(timings.driverFoundDisplay)
            try Task.checkCancellation()
            phase = .driverArriving(driver)

            try await startTripUseCase.execute()
            try Task.checkCancellation()
            phase = .tripStarted(driver)

            try await completeTripUseCase.execute()
            try Task.checkCancellation()
            phase = .tripCompleted

            try await sleep(timings.tripCompletedDisplay)
            try Task.checkCancellation()
            phase = .idle
        } catch is CancellationError {
            // Cancellation is owned by `cancelTrip`, which already set the phase.
        } catch {
            phase = .failed(message: errorPresenter.message(for: error))
        }
    }

    private func sleep(_ seconds: TimeInterval) async throws {
        guard seconds > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
