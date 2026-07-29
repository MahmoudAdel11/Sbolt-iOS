//
//  MockTripRepositoryTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

struct MockTripRepositoryTests {

    @Test func fetchReturnsSampleTripsOnSuccess() async throws {
        let sut = MockTripRepository(artificialDelay: 0)
        let trips = try await sut.fetchTripHistory()
        #expect(trips.count == 3)
        #expect(trips.first?.id == "trip-1")
    }

    @Test func fetchReturnsEmptyWhenNoTrips() async throws {
        let sut = MockTripRepository(trips: [], artificialDelay: 0)
        let trips = try await sut.fetchTripHistory()
        #expect(trips.isEmpty)
    }

    @Test func fetchFails() async {
        let sut = MockTripRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: TripHistoryError.historyUnavailable) {
            _ = try await sut.fetchTripHistory()
        }
    }

    @Test func refreshReturnsTripsOnSuccess() async throws {
        let sut = MockTripRepository(artificialDelay: 0)
        let trips = try await sut.refreshTripHistory()
        #expect(trips.count == 3)
    }

    @Test func refreshFails() async {
        let sut = MockTripRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: TripHistoryError.refreshFailed) {
            _ = try await sut.refreshTripHistory()
        }
    }
}
