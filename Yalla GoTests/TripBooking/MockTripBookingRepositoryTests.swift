//
//  MockTripBookingRepositoryTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 30/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

struct MockTripBookingRepositoryTests {

    private func makeSUT(behavior: MockTripBookingRepository.Behavior = .success)
    -> MockTripBookingRepository {
        MockTripBookingRepository(behavior: behavior,
                                  searchingDelay: 0,
                                  arrivingDelay: 0,
                                  tripDelay: 0,
                                  cancelDelay: 0)
    }

    @Test func findDriverReturnsDriverOnSuccess() async throws {
        let driver = try await makeSUT().findDriver()
        #expect(driver.id == "driver-1")
    }

    @Test func findDriverThrowsWhenNoDriver() async {
        let sut = makeSUT(behavior: .driverNotFound)
        await #expect(throws: TripBookingError.noDriverFound) {
            _ = try await sut.findDriver()
        }
    }

    @Test func findDriverThrowsOnNetworkFailure() async {
        let sut = makeSUT(behavior: .networkFailure)
        await #expect(throws: TripBookingError.networkUnavailable) {
            _ = try await sut.findDriver()
        }
    }

    @Test func lifecycleAndCancelDoNotThrowOnSuccess() async throws {
        let sut = makeSUT()
        try await sut.startTrip()
        try await sut.completeTrip()
        try await sut.cancelRequest()
    }

    @Test func findDriverHonoursCancellation() async {
        // A long delay lets the surrounding task be cancelled mid-wait.
        let sut = MockTripBookingRepository(searchingDelay: 5)
        let task = Task { try await sut.findDriver() }
        task.cancel()
        let result = await task.result
        #expect((try? result.get()) == nil)
    }
}
