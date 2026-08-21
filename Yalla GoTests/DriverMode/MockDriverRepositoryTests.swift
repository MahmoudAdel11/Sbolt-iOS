//
//  MockDriverRepositoryTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

struct MockDriverRepositoryTests {

    @Test func setOnlineStatusUpdatesDriverProfile() async throws {
        let sut = MockDriverRepository(artificialDelay: 0)

        let user = try await sut.setOnlineStatus(true)

        #expect(user.driverProfile?.isOnline == true)
    }

    @Test func fetchAvailableRidesRequiresOnline() async {
        let sut = MockDriverRepository(artificialDelay: 0)

        await #expect(throws: DriverError.notAuthorizedAsDriver) {
            _ = try await sut.fetchAvailableRides(near: Coordinate(latitude: 0, longitude: 0))
        }
    }

    @Test func fetchAvailableRidesSucceedsWhenOnline() async throws {
        let sut = MockDriverRepository(artificialDelay: 0)
        _ = try await sut.setOnlineStatus(true)

        let rides = try await sut.fetchAvailableRides(near: Coordinate(latitude: 0, longitude: 0))

        #expect(!rides.isEmpty)
    }

    @Test func acceptRideRemovesFromAvailableAndBecomesActive() async throws {
        let sut = MockDriverRepository(artificialDelay: 0)
        _ = try await sut.setOnlineStatus(true)
        let before = try await sut.fetchAvailableRides(near: Coordinate(latitude: 0, longitude: 0))
        let target = try #require(before.first)

        let accepted = try await sut.acceptRide(id: target.id)
        #expect(accepted.status == .accepted)

        let after = try await sut.fetchAvailableRides(near: Coordinate(latitude: 0, longitude: 0))
        #expect(!after.contains { $0.id == target.id })
    }

    @Test func acceptRideFailsForUnknownID() async {
        let sut = MockDriverRepository(artificialDelay: 0)
        _ = try? await sut.setOnlineStatus(true)

        await #expect(throws: DriverError.rideNoLongerAvailable) {
            _ = try await sut.acceptRide(id: "does-not-exist")
        }
    }

    @Test func completeRideSucceedsForActiveRide() async throws {
        let sut = MockDriverRepository(artificialDelay: 0)
        _ = try await sut.setOnlineStatus(true)
        let rides = try await sut.fetchAvailableRides(near: Coordinate(latitude: 0, longitude: 0))
        let target = try #require(rides.first)
        _ = try await sut.acceptRide(id: target.id)

        let completed = try await sut.completeRide(id: target.id)

        #expect(completed.status == .completed)
    }

    @Test func completeRideFailsWithoutAnActiveRide() async {
        let sut = MockDriverRepository(artificialDelay: 0)

        await #expect(throws: DriverError.rideNotCompletable) {
            _ = try await sut.completeRide(id: "ride-1")
        }
    }
}
