//
//  GetTripHistoryUseCaseTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

struct GetTripHistoryUseCaseTests {

    @Test func returnsFirstPageOnSuccess() async throws {
        let repository = MockTripRepository(artificialDelay: 0)
        let sut = GetTripHistoryUseCase(repository: repository)

        let page = try await sut.execute()

        #expect(page.trips.count == 4)
        #expect(page.hasMore == false)
    }

    @Test func returnsEmptyWhenNoTrips() async throws {
        let repository = MockTripRepository(trips: [], artificialDelay: 0)
        let sut = GetTripHistoryUseCase(repository: repository)

        let page = try await sut.execute()

        #expect(page.trips.isEmpty)
        #expect(page.hasMore == false)
    }

    @Test func respectsCustomPageSizeAndOffset() async throws {
        let repository = MockTripRepository(trips: MockTripRepository.manyTrips(count: 25), artificialDelay: 0)
        let sut = GetTripHistoryUseCase(repository: repository, pageSize: 10)

        let firstPage = try await sut.execute(offset: 0)
        #expect(firstPage.trips.count == 10)
        #expect(firstPage.hasMore == true)

        let secondPage = try await sut.execute(offset: 10)
        #expect(secondPage.trips.count == 10)
        #expect(secondPage.hasMore == true)

        let thirdPage = try await sut.execute(offset: 20)
        #expect(thirdPage.trips.count == 5)
        #expect(thirdPage.hasMore == false)
    }

    @Test func propagatesFailure() async {
        let repository = MockTripRepository(behavior: .failure, artificialDelay: 0)
        let sut = GetTripHistoryUseCase(repository: repository)

        await #expect(throws: TripHistoryError.historyUnavailable) {
            _ = try await sut.execute()
        }
    }

    @Test func refreshRoutesToRefreshEndpoint() async {
        let repository = MockTripRepository(behavior: .failure, artificialDelay: 0)
        let sut = GetTripHistoryUseCase(repository: repository)

        // Refresh maps to the repository's refresh path, which throws refreshFailed.
        await #expect(throws: TripHistoryError.refreshFailed) {
            _ = try await sut.execute(refresh: true)
        }
    }
}
