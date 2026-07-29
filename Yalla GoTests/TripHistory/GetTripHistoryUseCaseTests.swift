//
//  GetTripHistoryUseCaseTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

struct GetTripHistoryUseCaseTests {

    @Test func returnsTripsOnSuccess() async throws {
        let repository = MockTripRepository(artificialDelay: 0)
        let sut = GetTripHistoryUseCase(repository: repository)

        let trips = try await sut.execute()

        #expect(trips.count == 3)
    }

    @Test func returnsEmptyWhenNoTrips() async throws {
        let repository = MockTripRepository(trips: [], artificialDelay: 0)
        let sut = GetTripHistoryUseCase(repository: repository)

        let trips = try await sut.execute()

        #expect(trips.isEmpty)
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
