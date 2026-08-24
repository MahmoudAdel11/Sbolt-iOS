//
//  TripBookingUseCaseTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

struct TripBookingUseCaseTests {

    private let pickup = Coordinate(latitude: 30.05, longitude: 31.23)
    private let dropoff = Coordinate(latitude: 30.06, longitude: 31.24)

    @Test func requestRideReturnsTrip() async throws {
        let sut = RequestRideUseCase(repository: MockTripBookingRepository())
        let trip = try await sut.execute(pickup: pickup, dropoff: dropoff)
        #expect(trip.status == .requested)
    }

    @Test func requestRidePropagatesFailure() async {
        let sut = RequestRideUseCase(repository: MockTripBookingRepository(behavior: .activeRideAlreadyExists))
        await #expect(throws: RideError.activeRideAlreadyExists) {
            _ = try await sut.execute(pickup: pickup, dropoff: dropoff)
        }
    }

    @Test func cancelRideReturnsCancelledTrip() async throws {
        let repository = MockTripBookingRepository()
        let requested = try await repository.requestRide(pickup: pickup, dropoff: dropoff)
        let sut = CancelRideUseCase(repository: repository)

        let cancelled = try await sut.execute(rideID: requested.id)
        #expect(cancelled.status == .cancelled)
    }

    @Test func submitRatingSucceeds() async throws {
        let repository = MockTripBookingRepository()
        let requested = try await repository.requestRide(pickup: pickup, dropoff: dropoff)
        let sut = SubmitRatingUseCase(repository: repository)

        try await sut.execute(rideID: requested.id, score: 5)
        // No throw is success — the mock has no persistent rating store to assert against.
    }

    @Test func submitRatingPropagatesFailure() async {
        let repository = MockTripBookingRepository(behavior: .networkFailure)
        let sut = SubmitRatingUseCase(repository: repository)

        await #expect(throws: RideError.networkUnavailable) {
            try await sut.execute(rideID: "ride-1", score: 5)
        }
    }

    @Test func pollRideStatusYieldsUntilTerminal() async throws {
        let repository = MockTripBookingRepository(statusProgression: [.requested, .accepted, .completed])
        let requested = try await repository.requestRide(pickup: pickup, dropoff: dropoff)
        let sut = PollRideStatusUseCase(repository: repository, interval: 0)

        var statuses: [TripStatus] = []
        for try await trip in sut.execute(rideID: requested.id) {
            statuses.append(trip.status)
        }

        #expect(statuses == [.requested, .accepted, .completed])
    }
}
