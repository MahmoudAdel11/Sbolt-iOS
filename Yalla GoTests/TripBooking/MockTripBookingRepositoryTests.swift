//
//  MockTripBookingRepositoryTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

struct MockTripBookingRepositoryTests {

    private let pickup = Coordinate(latitude: 30.05, longitude: 31.23)
    private let dropoff = Coordinate(latitude: 30.06, longitude: 31.24)

    @Test func requestRideReturnsRequestedTrip() async throws {
        let sut = MockTripBookingRepository()
        let trip = try await sut.requestRide(pickup: pickup, dropoff: dropoff)
        #expect(trip.status == .requested)
        #expect(trip.driverID == nil)
    }

    @Test func requestRideThrowsWhenActiveRideExists() async {
        let sut = MockTripBookingRepository(behavior: .activeRideAlreadyExists)
        await #expect(throws: RideError.activeRideAlreadyExists) {
            _ = try await sut.requestRide(pickup: pickup, dropoff: dropoff)
        }
    }

    @Test func requestRideThrowsOnNetworkFailure() async {
        let sut = MockTripBookingRepository(behavior: .networkFailure)
        await #expect(throws: RideError.networkUnavailable) {
            _ = try await sut.requestRide(pickup: pickup, dropoff: dropoff)
        }
    }

    @Test func getRideDetailsAdvancesThroughProgression() async throws {
        let sut = MockTripBookingRepository(statusProgression: [.requested, .accepted, .completed])
        let trip = try await sut.requestRide(pickup: pickup, dropoff: dropoff)

        let first = try await sut.getRideDetails(id: trip.id)
        #expect(first.status == .requested)

        let second = try await sut.getRideDetails(id: trip.id)
        #expect(second.status == .accepted)
        #expect(second.driverID != nil)

        let third = try await sut.getRideDetails(id: trip.id)
        #expect(third.status == .completed)

        // Terminal — further polls return the same terminal state.
        let fourth = try await sut.getRideDetails(id: trip.id)
        #expect(fourth.status == .completed)
    }

    @Test func getRideDetailsThrowsForUnknownRide() async {
        let sut = MockTripBookingRepository()
        await #expect(throws: RideError.rideNotFound) {
            _ = try await sut.getRideDetails(id: "missing")
        }
    }

    @Test func cancelRideSucceedsWhileNonTerminal() async throws {
        let sut = MockTripBookingRepository()
        let trip = try await sut.requestRide(pickup: pickup, dropoff: dropoff)
        let cancelled = try await sut.cancelRide(id: trip.id)
        #expect(cancelled.status == .cancelled)
    }

    @Test func cancelRideFailsWhenAlreadyTerminal() async throws {
        let sut = MockTripBookingRepository(statusProgression: [.completed])
        let trip = try await sut.requestRide(pickup: pickup, dropoff: dropoff)
        _ = try await sut.getRideDetails(id: trip.id) // advances to .completed

        await #expect(throws: RideError.cancellationFailed) {
            _ = try await sut.cancelRide(id: trip.id)
        }
    }
}
