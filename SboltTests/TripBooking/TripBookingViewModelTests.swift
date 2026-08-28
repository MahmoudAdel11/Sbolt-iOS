//
//  TripBookingViewModelTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
import Combine
@testable import Sbolt

/// Throws a fixed error regardless of call — used to test how the ViewModel
/// reacts to a specific typed error without widening `MockTripBookingRepository`.
private struct FailingTripBookingRepository: TripBookingRepository {
    let error: Error
    func requestRide(
        pickup: Coordinate, dropoff: Coordinate, tier: RideType,
        pickupAddress: String?, dropoffAddress: String?
    ) async throws -> Trip { throw error }
    func cancelRide(id: String) async throws -> Trip { throw error }
    func getRideDetails(id: String) async throws -> Trip { throw error }
    func getActiveRide() async throws -> Trip? { throw error }
    func submitRating(rideID: String, score: Int) async throws { throw error }
}

@MainActor
struct TripBookingViewModelTests {

    private let pickup = Coordinate(latitude: 30.05, longitude: 31.23)
    private let dropoff = Coordinate(latitude: 30.06, longitude: 31.24)

    private func makeSUT(behavior: MockTripBookingRepository.Behavior = .success,
                         statusProgression: [TripStatus] = [.requested, .accepted, .completed],
                         reverseGeocoding: ReverseGeocoding = StubReverseGeocoding())
    -> (TripBookingViewModel, MockTripBookingRepository) {
        let repository = MockTripBookingRepository(behavior: behavior, statusProgression: statusProgression)
        let sut = TripBookingViewModel(
            requestRideUseCase: RequestRideUseCase(repository: repository),
            cancelRideUseCase: CancelRideUseCase(repository: repository),
            pollRideStatusUseCase: PollRideStatusUseCase(repository: repository, interval: 0),
            getActiveRideUseCase: GetActiveRideUseCase(repository: repository),
            timings: .immediate,
            reverseGeocoding: reverseGeocoding
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
        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        #expect(sut.phase == .requesting)
    }

    @Test func confirmTripResolvesAndSendsPickupAndDropoffAddresses() async throws {
        let geocoding = StubReverseGeocoding(behavior: .success("New Cairo"))
        // Never auto-advances to terminal - same reasoning as
        // `checkForActiveRideRehydratesPhaseWhenAnActiveRideExists` above:
        // awaiting `bookingTask?.value` to completion would also wait out the
        // rating-decision gate after `.completed`, which nothing here resolves.
        let (sut, _) = makeSUT(statusProgression: [.requested], reverseGeocoding: geocoding)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        try await Task.sleep(nanoseconds: 50_000_000)

        guard case let .active(trip) = sut.phase else {
            Issue.record("Expected .active phase after a successful request")
            return
        }
        #expect(trip.pickupAddress == "New Cairo")
        #expect(trip.dropoffAddress == "New Cairo")
        // Both coordinates resolved - confirms both pickup and dropoff are
        // geocoded (concurrently, not just one of them).
        #expect(geocoding.requestedCoordinates.count == 2)
        #expect(geocoding.requestedCoordinates.contains(pickup))
        #expect(geocoding.requestedCoordinates.contains(dropoff))
    }

    /// Per the confirmed decision, a geocoding failure must never block ride
    /// creation - the request still goes out, just with nil addresses.
    @Test func confirmTripStillSucceedsWhenGeocodingFails() async throws {
        let (sut, _) = makeSUT(statusProgression: [.requested],
                               reverseGeocoding: StubReverseGeocoding(behavior: .failure))

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        try await Task.sleep(nanoseconds: 50_000_000)

        guard case let .active(trip) = sut.phase else {
            Issue.record("Expected .active phase even when geocoding fails")
            return
        }
        #expect(trip.pickupAddress == nil)
        #expect(trip.dropoffAddress == nil)
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

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        await sut.bookingTask?.value

        #expect(recorded.contains(.requesting))
        #expect(recorded.contains { if case let .active(trip) = $0 { return trip.status == .requested }; return false })
        #expect(recorded.contains { if case let .active(trip) = $0 { return trip.status == .accepted }; return false })
        #expect(recorded.contains { if case .completed = $0 { return true }; return false })
        #expect(sut.phase == .idle)
    }

    @Test func activeRideAlreadyExistsEndsInFailed() async {
        let (sut, _) = makeSUT(behavior: .activeRideAlreadyExists)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        await sut.bookingTask?.value

        #expect(sut.phase == .failed(message: "You already have an active ride."))
    }

    @Test func networkFailureEndsInFailed() async {
        let (sut, _) = makeSUT(behavior: .networkFailure)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        await sut.bookingTask?.value

        #expect(sut.phase == .failed(message: "No internet connection. Please try again."))
    }

    @Test func cancelWhileActiveReturnsToIdle() async throws {
        let (sut, _) = makeSUT(statusProgression: [.requested]) // never auto-advances to terminal

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
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

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        await sut.bookingTask?.value
        #expect(sut.phase == .failed(message: "You already have an active ride."))

        sut.retry()
        #expect(sut.phase == .idle)
    }

    @Test func confirmIgnoredWhileBookingInProgress() {
        let (sut, _) = makeSUT()
        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        #expect(sut.phase == .requesting)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .premium) // ignored — not idle
        #expect(sut.phase == .requesting)
    }

    @Test func completedPhaseWaitsForRatingDecisionBeforeResetting() async {
        let (sut, _) = makeSUT() // timings: .immediate — resetAfterTerminal == 0

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
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
            getActiveRideUseCase: GetActiveRideUseCase(repository: repository),
            timings: .immediate
        )

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        await sut.bookingTask?.value

        #expect(sut.isSessionExpired == true)
        #expect(sut.phase == .failed(message: "Your session has expired. Please log in again."))
    }

    @Test func otherFailuresDoNotSetSessionExpiredFlag() async {
        let (sut, _) = makeSUT(behavior: .activeRideAlreadyExists)

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        await sut.bookingTask?.value

        #expect(sut.isSessionExpired == false)
    }

    // MARK: - checkForActiveRide

    @Test func checkForActiveRideRehydratesPhaseWhenAnActiveRideExists() async throws {
        let (sut, repository) = makeSUT(statusProgression: [.requested]) // never auto-advances
        // Seed the backend/mock with a pending ride WITHOUT going through the
        // view model - simulates a ride that exists server-side but whose
        // in-memory `phase` was never set in this app session (relaunch).
        _ = try await repository.requestRide(pickup: pickup, dropoff: dropoff, tier: .economy)
        #expect(sut.phase == .idle) // confirms the seed above didn't touch phase

        sut.checkForActiveRide()
        // Never awaits `bookingTask?.value` to completion here: with
        // `statusProgression: [.requested]` the poll loop (interval 0) never
        // reaches a terminal status, so the task never finishes - same reason
        // `cancelWhileActiveReturnsToIdle` above uses a short sleep instead.
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.isCancellable == true)
        if case let .active(trip) = sut.phase {
            #expect(trip.status == .requested)
        } else {
            Issue.record("Expected .active, got \(sut.phase)")
        }
    }

    @Test func checkForActiveRideIsANoOpWhenThereIsNoActiveRide() async {
        let (sut, _) = makeSUT()

        sut.checkForActiveRide()
        await sut.bookingTask?.value

        #expect(sut.phase == .idle)
    }

    @Test func checkForActiveRideDoesNotClobberARequestingFlowAlreadyInProgress() {
        let (sut, _) = makeSUT()

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        #expect(sut.phase == .requesting)

        sut.checkForActiveRide() // must be a no-op - a flow is already in progress
        #expect(sut.phase == .requesting)
    }

    @Test func checkForActiveRideDoesNotClobberAnAlreadyActiveTrip() async throws {
        let (sut, _) = makeSUT(statusProgression: [.requested]) // never auto-advances

        sut.confirmTrip(pickup: pickup, dropoff: dropoff, tier: .economy)
        try await Task.sleep(nanoseconds: 50_000_000) // let the first poll publish .active
        guard case let .active(before) = sut.phase else {
            Issue.record("Expected .active before exercising the guard, got \(sut.phase)")
            return
        }

        sut.checkForActiveRide() // must be a no-op - already tracking a live ride
        guard case let .active(after) = sut.phase else {
            Issue.record("Expected still .active, got \(sut.phase)")
            return
        }
        #expect(after == before)
    }
}
