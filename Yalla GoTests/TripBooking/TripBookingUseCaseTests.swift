//
//  TripBookingUseCaseTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 30/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

struct TripBookingUseCaseTests {

    private func makeRepository(behavior: MockTripBookingRepository.Behavior = .success)
    -> MockTripBookingRepository {
        MockTripBookingRepository(behavior: behavior,
                                  searchingDelay: 0,
                                  arrivingDelay: 0,
                                  tripDelay: 0,
                                  cancelDelay: 0)
    }

    @Test func findDriverReturnsDriver() async throws {
        let sut = FindDriverUseCase(repository: makeRepository())
        let driver = try await sut.execute()
        #expect(driver.name == "Ahmed Hassan")
    }

    @Test func findDriverPropagatesFailure() async {
        let sut = FindDriverUseCase(repository: makeRepository(behavior: .driverNotFound))
        await #expect(throws: TripBookingError.noDriverFound) {
            _ = try await sut.execute()
        }
    }

    @Test func startTripCompletes() async throws {
        let sut = StartTripUseCase(repository: makeRepository())
        try await sut.execute()
    }

    @Test func completeTripCompletes() async throws {
        let sut = CompleteTripUseCase(repository: makeRepository())
        try await sut.execute()
    }

    @Test func cancelTripCompletes() async throws {
        let sut = CancelTripUseCase(repository: makeRepository())
        try await sut.execute()
    }
}
