//
//  TripBookingViewModelTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
import Combine
@testable import Yalla_Go

/// Throws a fixed error regardless of call — used to test how the ViewModel
/// reacts to a specific typed error without widening `MockTripBookingRepository`.
private struct FailingTripBookingRepository: TripBookingRepository {
    let error: Error
    func requestRide(pickup: Coordinate, dropoff: Coordinate) async throws -> Trip { throw error }
    func cancelRide(id: String) async throws -> Trip { throw error }
    func getRideDetails(id: String) async throws -> Trip { throw error }
    func submitRating(rideID: String, score: Int) async throws { throw error }
}

@MainActor
struct TripBookingViewModelTests {

    private let pickup = Coordinate(latitude: 30.05, longitude: 31.23)
    private let dropoff = Coordinate(latitude: 30.06, longitude: 31.24)

    private func makeSUT(behavior: MockTripBookingRepository.Behavior = .success,
                         statusProgression: [TripStatus] = [.requested, .accepted, .completed])
    -> (TripBookingViewModel, MockTripBookingRepository) {
        let repository = MockTripBookingRepository(behavior: behavior, statusProgression: statusProgression)
        let sut = TripBookingViewModel(
            requestRideUseCase: RequestRideUseCase(repository: repository),
            cancelRideUseCase: CancelRideUseCase(repository: repository),
            pollRideStatusUseCase: PollRideStatusUseCase(repository: repository, interval: 0),
            timings: .immediate
        )
        return (sut, repository)
    }

    @Test func startsIdle() {
        let (sut, _) = makeSUT()
        #expect(sut.phase == .idle)
        #expect(sut.isCancellable == false)
    }

    @Test func confirmSetsRequestingSynchronously() {
        let (sut, _) = makeSUT()
        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        #expect(sut.phase == .requesting)
        #expect(sut.estimatedFare == 42)
    }

    @Test func successfulFlowTransitionsThroughStatusesToIdle() async {
        let (sut, _) = makeSUT()
        var recorded: [TripPhase] = []
        // The `.completed` → `.idle` reset now waits on a rating decision (see
        // `proceedPastRatingPrompt` tests below) — a real UI would present the
        // rating sheet here; this test stands in for "the rider decided" the
        // instant `.completed` is observed, so the rest of the flow proceeds
        // exactly as it did before that gate existed.
        let cancellable = sut.$phase.sink { phase in
            recorded.append(phase)
            if case .completed = phase { sut.proceedPastRatingPrompt() }
        }
        defer { cancellable.cancel() }

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        await sut.bookingTask?.value

        #expect(recorded.contains(.requesting))
        #expect(recorded.contains { if case let .active(trip) = $0 { return trip.status == .requested }; return false })
        #expect(recorded.contains { if case let .active(trip) = $0 { return trip.status == .accepted }; return false })
        #expect(recorded.contains { if case .completed = $0 { return true }; return false })
        #expect(sut.phase == .idle)
        #expect(sut.estimatedFare == nil)
    }

    @Test func activeRideAlreadyExistsEndsInFailed() async {
        let (sut, _) = makeSUT(behavior: .activeRideAlreadyExists)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        await sut.bookingTask?.value

        #expect(sut.phase == .failed(message: "You already have an active ride."))
    }

    @Test func networkFailureEndsInFailed() async {
        let (sut, _) = makeSUT(behavior: .networkFailure)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        await sut.bookingTask?.value

        #expect(sut.phase == .failed(message: "No internet connection. Please try again."))
    }

    @Test func cancelWhileActiveReturnsToIdle() async throws {
        let (sut, _) = makeSUT(statusProgression: [.requested]) // never auto-advances to terminal

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        // Wait for the first poll to publish an .active phase.
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(sut.isCancellable == true)

        sut.cancelTrip()
        await sut.cleanupTask?.value
        #expect(sut.phase == .idle)
    }

    @Test func cancelIsIgnoredWhenNotCancellable() {
        let (sut, _) = makeSUT()
        sut.cancelTrip() // idle is not cancellable
        #expect(sut.phase == .idle)
    }

    @Test func retryFromFailedReturnsToIdle() async {
        let (sut, _) = makeSUT(behavior: .activeRideAlreadyExists)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        await sut.bookingTask?.value
        #expect(sut.phase == .failed(message: "You already have an active ride."))

        sut.retry()
        #expect(sut.phase == .idle)
    }

    @Test func confirmIgnoredWhileBookingInProgress() {
        let (sut, _) = makeSUT()
        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        #expect(sut.phase == .requesting)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 99) // ignored — not idle
        #expect(sut.estimatedFare == 42)
    }

    @Test func completedPhaseWaitsForRatingDecisionBeforeResetting() async {
        let (sut, _) = makeSUT() // timings: .immediate — resetAfterTerminal == 0

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        // Give the booking task time to reach `.completed` and start waiting.
        // No real production delay to race against here: with resetAfterTerminal
        // == 0, if the gate didn't exist the phase would already be `.idle`
        // well before this returns.
        try? await Task.sleep(nanoseconds: 100_000_000)

        guard case .completed = sut.phase else {
            Issue.record("Expected .completed, got \(sut.phase)")
            return
        }

        sut.proceedPastRatingPrompt()
        await sut.bookingTask?.value

        #expect(sut.phase == .idle)
    }

    @Test func proceedPastRatingPromptIsANoOpWhenNothingIsWaiting() {
        let (sut, _) = makeSUT()
        // No booking in flight at all - must not crash or hang a future call.
        sut.proceedPastRatingPrompt()
        #expect(sut.phase == .idle)
    }

    @Test func sessionExpiredSetsFlagAndClearMessage() async {
        let repository = FailingTripBookingRepository(error: RideError.sessionExpired)
        let sut = TripBookingViewModel(
            requestRideUseCase: RequestRideUseCase(repository: repository),
            cancelRideUseCase: CancelRideUseCase(repository: repository),
            pollRideStatusUseCase: PollRideStatusUseCase(repository: repository, interval: 0),
            timings: .immediate
        )

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        await sut.bookingTask?.value

        #expect(sut.isSessionExpired == true)
        #expect(sut.phase == .failed(message: "Your session has expired. Please log in again."))
    }

    @Test func otherFailuresDoNotSetSessionExpiredFlag() async {
        let (sut, _) = makeSUT(behavior: .activeRideAlreadyExists)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, estimatedFare: 42)
        await sut.bookingTask?.value

        #expect(sut.isSessionExpired == false)
    }
}
