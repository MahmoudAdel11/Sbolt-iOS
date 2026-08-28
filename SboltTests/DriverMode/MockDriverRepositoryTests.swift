//
//  MockDriverRepositoryTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

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

    @Test func startRideSucceedsForAcceptedActiveRide() async throws {
        let sut = MockDriverRepository(artificialDelay: 0)
        _ = try await sut.setOnlineStatus(true)
        let rides = try await sut.fetchAvailableRides(near: Coordinate(latitude: 0, longitude: 0))
        let target = try #require(rides.first)
        _ = try await sut.acceptRide(id: target.id)

        let started = try await sut.startRide(id: target.id)

        #expect(started.status == .ongoing)
    }

    @Test func startRideFailsWithoutAnActiveRide() async {
        let sut = MockDriverRepository(artificialDelay: 0)

        await #expect(throws: DriverError.rideNotStartable) {
            _ = try await sut.startRide(id: "ride-1")
        }
    }

    /// Reverses a previously-passing test's expected outcome: completing directly
    /// from .accepted (skipping /start) used to succeed when start was advisory.
    /// Per an explicit product decision, .ongoing is now required, so this must
    /// now fail with the distinguishable .rideNotStarted error instead.
    @Test func completeRideFailsWithRideNotStartedWhenStillAccepted() async throws {
        let sut = MockDriverRepository(artificialDelay: 0)
        _ = try await sut.setOnlineStatus(true)
        let rides = try await sut.fetchAvailableRides(near: Coordinate(latitude: 0, longitude: 0))
        let target = try #require(rides.first)
        _ = try await sut.acceptRide(id: target.id)

        await #expect(throws: DriverError.rideNotStarted) {
            _ = try await sut.completeRide(id: target.id)
        }
    }

    @Test func completeRideSucceedsForOngoingActiveRide() async throws {
        let sut = MockDriverRepository(artificialDelay: 0)
        _ = try await sut.setOnlineStatus(true)
        let rides = try await sut.fetchAvailableRides(near: Coordinate(latitude: 0, longitude: 0))
        let target = try #require(rides.first)
        _ = try await sut.acceptRide(id: target.id)
        _ = try await sut.startRide(id: target.id)

        let completed = try await sut.completeRide(id: target.id)

        #expect(completed.status == .completed)
    }

    @Test func completeRideFailsWithoutAnActiveRide() async {
        let sut = MockDriverRepository(artificialDelay: 0)

        await #expect(throws: DriverError.rideNotCompletable) {
            _ = try await sut.completeRide(id: "ride-1")
        }
    }

    @Test func updateVehicleSetsAllProvidedFields() async throws {
        let sut = MockDriverRepository(artificialDelay: 0)

        let user = try await sut.updateVehicle(
            vehicleType: "Vespa", vehicleColor: "Red", licensePlate: "XYZ-999", scooterType: .premium
        )

        #expect(user.driverProfile?.vehicleType == "Vespa")
        #expect(user.driverProfile?.vehicleColor == "Red")
        #expect(user.driverProfile?.licensePlate == "XYZ-999")
        #expect(user.driverProfile?.scooterType == .premium)
    }

    @Test func updateVehicleOnlyTouchesProvidedFields() async throws {
        let sut = MockDriverRepository(artificialDelay: 0)
        _ = try await sut.updateVehicle(
            vehicleType: "Vespa", vehicleColor: "Red", licensePlate: "XYZ-999", scooterType: .economy
        )

        let user = try await sut.updateVehicle(
            vehicleType: nil, vehicleColor: "Black", licensePlate: nil, scooterType: nil
        )

        // Only vehicleColor was provided this time - everything else survives.
        #expect(user.driverProfile?.vehicleType == "Vespa")
        #expect(user.driverProfile?.vehicleColor == "Black")
        #expect(user.driverProfile?.licensePlate == "XYZ-999")
        #expect(user.driverProfile?.scooterType == .economy)
    }

    @Test func updateVehicleThrowsOnNetworkFailure() async {
        let sut = MockDriverRepository(behavior: .networkFailure, artificialDelay: 0)

        await #expect(throws: DriverError.networkUnavailable) {
            _ = try await sut.updateVehicle(
                vehicleType: nil, vehicleColor: nil, licensePlate: nil, scooterType: nil
            )
        }
    }
}
