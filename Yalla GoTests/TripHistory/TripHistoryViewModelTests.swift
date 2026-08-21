//
//  TripHistoryViewModelTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

/// Throws a fixed error regardless of call — used to test how the ViewModel
/// reacts to a specific typed error without widening `MockTripRepository`.
private struct FailingTripRepository: TripRepository {
    let error: Error
    func fetchTripHistory(offset: Int, limit: Int, view: RideView) async throws -> TripHistoryPage { throw error }
    func refreshTripHistory(limit: Int, view: RideView) async throws -> TripHistoryPage { throw error }
}

@MainActor
struct TripHistoryViewModelTests {

    private func makeSUT(trips: [Trip] = MockTripRepository.sampleTrips(),
                         behavior: MockTripRepository.Behavior = .success,
                         pageSize: Int = GetTripHistoryUseCase.defaultPageSize) -> TripHistoryViewModel {
        let repository = MockTripRepository(trips: trips, behavior: behavior, artificialDelay: 0)
        return TripHistoryViewModel(
            getTripHistoryUseCase: GetTripHistoryUseCase(repository: repository, pageSize: pageSize)
        )
    }

    @Test func startsInIdleState() {
        let sut = makeSUT()
        #expect(sut.trips.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.hasMore == false)
        #expect(sut.errorMessage == nil)
        // Not yet loaded, so it is not considered a populated screen.
        #expect(sut.isEmpty == true)
    }

    @Test func loadSuccessPublishesTrips() async {
        let sut = makeSUT()

        sut.loadTripHistory()
        await sut.activeTask?.value

        #expect(sut.trips.count == 4)
        #expect(sut.hasMore == false)
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

        #expect(sut.trips.count == 4)
        #expect(sut.errorMessage == nil)
    }

    @Test func refreshFailurePublishesError() async {
        let sut = makeSUT(behavior: .failure)

        sut.refresh()
        await sut.activeTask?.value

        #expect(sut.errorMessage == "We couldn't refresh your trips. Please try again.")
    }

    @Test func loadMoreAppendsSecondPage() async {
        let sut = makeSUT(trips: MockTripRepository.manyTrips(count: 25), pageSize: 20)

        sut.loadTripHistory()
        await sut.activeTask?.value
        #expect(sut.trips.count == 20)
        #expect(sut.hasMore == true)

        sut.loadMore()
        #expect(sut.isLoadingMore == true) // set synchronously
        await sut.loadMoreTask?.value

        #expect(sut.trips.count == 25)
        #expect(sut.hasMore == false)
        #expect(sut.isLoadingMore == false)
        // No duplicates, no gaps: exactly trip-0...trip-24, each once, in order.
        #expect(sut.trips.map(\.id) == (0..<25).map { "trip-\($0)" })
    }

    @Test func loadMoreIgnoredWhenNoMorePages() async {
        let sut = makeSUT() // 4 trips, single page

        sut.loadTripHistory()
        await sut.activeTask?.value
        #expect(sut.hasMore == false)

        sut.loadMore() // ignored — hasMore is false
        #expect(sut.isLoadingMore == false)
        #expect(sut.trips.count == 4)
    }

    @Test func loadMoreIgnoredWhileAlreadyLoadingMore() async {
        let sut = makeSUT(trips: MockTripRepository.manyTrips(count: 45), pageSize: 20)

        sut.loadTripHistory()
        await sut.activeTask?.value
        #expect(sut.trips.count == 20)

        sut.loadMore()
        sut.loadMore() // ignored — a load-more is already in flight
        await sut.loadMoreTask?.value

        // Exactly one additional page was appended, not two.
        #expect(sut.trips.count == 40)
    }

    @Test func sessionExpiredSetsFlagAndClearMessage() async {
        let repository = FailingTripRepository(error: TripHistoryError.sessionExpired)
        let sut = TripHistoryViewModel(getTripHistoryUseCase: GetTripHistoryUseCase(repository: repository))

        sut.loadTripHistory()
        await sut.activeTask?.value

        #expect(sut.isSessionExpired == true)
        #expect(sut.errorMessage == "Your session has expired. Please log in again.")
    }

    @Test func otherErrorsDoNotSetSessionExpiredFlag() async {
        let sut = makeSUT(behavior: .failure)

        sut.loadTripHistory()
        await sut.activeTask?.value

        #expect(sut.isSessionExpired == false)
    }
}
