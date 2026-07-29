//
//  TripHistoryViewModelTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

@MainActor
struct TripHistoryViewModelTests {

    private func makeSUT(trips: [Trip] = MockTripRepository.sampleTrips(),
                         behavior: MockTripRepository.Behavior = .success) -> TripHistoryViewModel {
        let repository = MockTripRepository(trips: trips, behavior: behavior, artificialDelay: 0)
        return TripHistoryViewModel(getTripHistoryUseCase: GetTripHistoryUseCase(repository: repository))
    }

    @Test func startsInIdleState() {
        let sut = makeSUT()
        #expect(sut.trips.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
        // Not yet loaded, so it is not considered a populated screen.
        #expect(sut.isEmpty == true)
    }

    @Test func loadSuccessPublishesTrips() async {
        let sut = makeSUT()

        sut.loadTripHistory()
        await sut.activeTask?.value

        #expect(sut.trips.count == 3)
        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
        #expect(sut.isEmpty == false)
    }

    @Test func loadSuccessWithNoTripsIsEmptyState() async {
        let sut = makeSUT(trips: [])

        sut.loadTripHistory()
        await sut.activeTask?.value

        #expect(sut.trips.isEmpty)
        #expect(sut.errorMessage == nil)
        #expect(sut.isEmpty == true)
    }

    @Test func loadFailurePublishesError() async {
        let sut = makeSUT(behavior: .failure)

        sut.loadTripHistory()
        await sut.activeTask?.value

        #expect(sut.trips.isEmpty)
        #expect(sut.errorMessage == "We couldn't load your trips. Please try again.")
        #expect(sut.isEmpty == false) // error state, not empty state
    }

    @Test func setsLoadingWhileRequestIsInFlight() async {
        let sut = makeSUT()

        sut.loadTripHistory()
        #expect(sut.isLoading == true) // set synchronously before the task runs

        await sut.activeTask?.value
        #expect(sut.isLoading == false)
    }

    @Test func refreshSuccessPublishesTrips() async {
        let sut = makeSUT()

        sut.refresh()
        await sut.activeTask?.value

        #expect(sut.trips.count == 3)
        #expect(sut.errorMessage == nil)
    }

    @Test func refreshFailurePublishesError() async {
        let sut = makeSUT(behavior: .failure)

        sut.refresh()
        await sut.activeTask?.value

        #expect(sut.errorMessage == "We couldn't refresh your trips. Please try again.")
    }
}
