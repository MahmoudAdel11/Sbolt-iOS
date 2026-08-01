//
//  TripBookingViewModelTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 30/07/2026.
//

import Testing
import Foundation
import Combine
@testable import Yalla_Go

@MainActor
struct TripBookingViewModelTests {

    private func makeSUT(behavior: MockTripBookingRepository.Behavior = .success)
    -> TripBookingViewModel {
        let repository = MockTripBookingRepository(behavior: behavior,
                                                   searchingDelay: 0,
                                                   arrivingDelay: 0,
                                                   tripDelay: 0,
                                                   cancelDelay: 0)
        let dependencies = TripBookingDependencies(repository: repository, timings: .immediate)
        return dependencies.makeTripBookingViewModel()
    }

    @Test func startsIdle() {
        let sut = makeSUT()
        #expect(sut.phase == .idle)
        #expect(sut.isCancellable == false)
    }

    @Test func confirmSetsSearchingSynchronously() {
        let sut = makeSUT()
        sut.confirmTrip()
        #expect(sut.phase == .searching)
        #expect(sut.isCancellable == true)
    }

    @Test func successfulFlowTransitionsThroughEveryPhaseToIdle() async {
        let sut = makeSUT()
        var recorded: [TripPhase] = []
        let cancellable = sut.$phase.sink { recorded.append($0) }
        defer { cancellable.cancel() }

        sut.confirmTrip()
        await sut.bookingTask?.value

        // Ordered transitions regardless of (zero) timing.
        #expect(recorded.contains(.searching))
        #expect(recorded.contains { if case .driverFound = $0 { return true }; return false })
        #expect(recorded.contains { if case .driverArriving = $0 { return true }; return false })
        #expect(recorded.contains { if case .tripStarted = $0 { return true }; return false })
        #expect(recorded.contains(.tripCompleted))
        #expect(sut.phase == .idle)
    }

    @Test func driverNotFoundEndsInFailed() async {
        let sut = makeSUT(behavior: .driverNotFound)

        sut.confirmTrip()
        await sut.bookingTask?.value

        #expect(sut.phase == .failed(message: "No drivers available right now. Please try again."))
    }

    @Test func networkFailureEndsInFailed() async {
        let sut = makeSUT(behavior: .networkFailure)

        sut.confirmTrip()
        await sut.bookingTask?.value

        #expect(sut.phase == .failed(message: "No internet connection. Please try again."))
    }

    @Test func cancelWhileSearchingReturnsToIdle() async {
        let sut = makeSUT()

        sut.confirmTrip()
        #expect(sut.phase == .searching)

        sut.cancelTrip()
        #expect(sut.phase == .cancelled) // set synchronously

        await sut.bookingTask?.value
        await sut.cleanupTask?.value
        #expect(sut.phase == .idle)
    }

    @Test func cancelIsIgnoredWhenNotCancellable() {
        let sut = makeSUT()
        // Idle is not cancellable.
        sut.cancelTrip()
        #expect(sut.phase == .idle)
    }

    @Test func retryFromFailedReentersSearching() async {
        let sut = makeSUT(behavior: .driverNotFound)

        sut.confirmTrip()
        await sut.bookingTask?.value
        #expect(sut.phase == .failed(message: "No drivers available right now. Please try again."))

        sut.retry()
        #expect(sut.phase == .searching) // reset + re-entered synchronously
    }

    @Test func confirmIgnoredWhileBookingInProgress() {
        let sut = makeSUT()
        sut.confirmTrip()
        #expect(sut.phase == .searching)

        sut.confirmTrip() // ignored — not idle
        #expect(sut.phase == .searching)
    }
}
