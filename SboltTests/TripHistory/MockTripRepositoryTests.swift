//
//  MockTripRepositoryTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

struct MockTripRepositoryTests {

    @Test func fetchReturnsSampleTripsOnSuccess() async throws {
        let sut = MockTripRepository(artificialDelay: 0)
        let page = try await sut.fetchTripHistory(offset: 0, limit: 20, view: .rider)
        #expect(page.trips.count == 4)
        #expect(page.trips.first?.id == "trip-1")
        #expect(page.hasMore == false)
    }

    @Test func fetchReturnsEmptyWhenNoTrips() async throws {
        let sut = MockTripRepository(trips: [], artificialDelay: 0)
        let page = try await sut.fetchTripHistory(offset: 0, limit: 20, view: .rider)
        #expect(page.trips.isEmpty)
        #expect(page.hasMore == false)
    }

    @Test func fetchFails() async {
        let sut = MockTripRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: TripHistoryError.historyUnavailable) {
            _ = try await sut.fetchTripHistory(offset: 0, limit: 20, view: .rider)
        }
    }

    @Test func refreshReturnsFirstPageOnSuccess() async throws {
        let sut = MockTripRepository(artificialDelay: 0)
        let page = try await sut.refreshTripHistory(limit: 20, view: .rider)
        #expect(page.trips.count == 4)
        #expect(page.hasMore == false)
    }

    @Test func refreshFails() async {
        let sut = MockTripRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: TripHistoryError.refreshFailed) {
            _ = try await sut.refreshTripHistory(limit: 20, view: .rider)
        }
    }

    @Test func paginationSlicesAcrossPageBoundaries() async throws {
        let sut = MockTripRepository(trips: MockTripRepository.manyTrips(count: 25), artificialDelay: 0)

        let first = try await sut.fetchTripHistory(offset: 0, limit: 20, view: .rider)
        #expect(first.trips.count == 20)
        #expect(first.trips.first?.id == "trip-0")
        #expect(first.trips.last?.id == "trip-19")
        #expect(first.hasMore == true)

        let second = try await sut.fetchTripHistory(offset: 20, limit: 20, view: .rider)
        #expect(second.trips.count == 5)
        #expect(second.trips.first?.id == "trip-20")
        #expect(second.trips.last?.id == "trip-24")
        #expect(second.hasMore == false)
    }

    @Test func paginationPastEndReturnsEmptyPage() async throws {
        let sut = MockTripRepository(trips: MockTripRepository.manyTrips(count: 5), artificialDelay: 0)
        let page = try await sut.fetchTripHistory(offset: 5, limit: 20, view: .rider)
        #expect(page.trips.isEmpty)
        #expect(page.hasMore == false)
    }
}
