//
//  MockTripBookingRepository.swift
//  Yalla Go
//

import Foundation

/// In-memory `TripBookingRepository` that simulates the ride backend's real
/// lifecycle: `requestRide` creates a ride in `.requested`, and each
/// subsequent `getRideDetails` call advances it one step through
/// `statusProgression` until it reaches a terminal state — so polling
/// against this mock behaves like polling the real API.
actor MockTripBookingRepository: TripBookingRepository {

    enum Behavior {
        case success
        case activeRideAlreadyExists
        case networkFailure
    }

    private let behavior: Behavior
    private let driverID: String
    /// Statuses returned on the 1st, 2nd, 3rd... `getRideDetails` call after
    /// request. The last entry should be terminal.
    private let statusProgression: [TripStatus]

    private var ride: Trip?
    private var detailCallCount = 0

    init(behavior: Behavior = .success,
         driverID: String = "driver-1",
         statusProgression: [TripStatus] = [.requested, .accepted, .ongoing, .completed]) {
        self.behavior = behavior
        self.driverID = driverID
        self.statusProgression = statusProgression
    }

    func requestRide(pickup: Coordinate, dropoff: Coordinate) async throws -> Trip {
        switch behavior {
        case .activeRideAlreadyExists:
            throw RideError.activeRideAlreadyExists
        case .networkFailure:
            throw RideError.networkUnavailable
        case .success:
            break
        }

        let trip = Trip(id: "ride-1",
                        riderID: "rider-1",
                        driverID: nil,
                        status: .requested,
                        pickupCoordinate: pickup,
                        destinationCoordinate: dropoff,
                        requestedAt: Date(),
                        acceptedAt: nil,
                        completedAt: nil,
                        cancelledAt: nil)
        ride = trip
        detailCallCount = 0
        return trip
    }

    func cancelRide(id: String) async throws -> Trip {
        guard var current = ride, current.id == id else {
            throw RideError.rideNotFound
        }
        guard !current.status.isTerminal else {
            throw RideError.cancellationFailed
        }
        current = Trip(id: current.id, riderID: current.riderID, driverID: current.driverID,
                       status: .cancelled, pickupCoordinate: current.pickupCoordinate,
                       destinationCoordinate: current.destinationCoordinate,
                       requestedAt: current.requestedAt, acceptedAt: current.acceptedAt,
                       completedAt: nil, cancelledAt: Date())
        ride = current
        return current
    }

    func getRideDetails(id: String) async throws -> Trip {
        guard let current = ride, current.id == id else {
            throw RideError.rideNotFound
        }
        guard !current.status.isTerminal else {
            return current
        }

        let index = min(detailCallCount, statusProgression.count - 1)
        let nextStatus = statusProgression[index]
        detailCallCount += 1

        let updated = Trip(
            id: current.id,
            riderID: current.riderID,
            driverID: nextStatus == .requested ? nil : driverID,
            status: nextStatus,
            pickupCoordinate: current.pickupCoordinate,
            destinationCoordinate: current.destinationCoordinate,
            requestedAt: current.requestedAt,
            acceptedAt: nextStatus == .accepted || nextStatus == .ongoing || nextStatus == .completed ? Date() : nil,
            completedAt: nextStatus == .completed ? Date() : nil,
            cancelledAt: nil
        )
        ride = updated
        return updated
    }
}
