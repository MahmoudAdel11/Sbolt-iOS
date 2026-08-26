//
//  DriverRepositorySpy.swift
//  Yalla GoTests
//

import Foundation
@testable import Yalla_Go

actor DriverRepositorySpy: DriverRepository {
    private(set) var setOnlineStatusCallCount = 0
    private(set) var lastRequestedIsOnline: Bool?
    private(set) var fetchAvailableRidesCallCount = 0
    private(set) var lastRequestedCoordinate: Coordinate?
    private(set) var acceptRideCallCount = 0
    private(set) var lastAcceptedRideID: String?
    private(set) var startRideCallCount = 0
    private(set) var lastStartedRideID: String?
    private(set) var completeRideCallCount = 0
    private(set) var lastCompletedRideID: String?

    private let setOnlineStatusResult: Result<User, Error>
    private let fetchAvailableRidesResult: Result<[Trip], Error>
    private let acceptRideResult: Result<Trip, Error>
    private let startRideResult: Result<Trip, Error>
    private let completeRideResult: Result<Trip, Error>

    init(setOnlineStatusResult: Result<User, Error> = .success(.driverStub),
         fetchAvailableRidesResult: Result<[Trip], Error> = .success([]),
         acceptRideResult: Result<Trip, Error> = .success(.driverStub),
         startRideResult: Result<Trip, Error> = .success(.driverStub),
         completeRideResult: Result<Trip, Error> = .success(.driverStub)) {
        self.setOnlineStatusResult = setOnlineStatusResult
        self.fetchAvailableRidesResult = fetchAvailableRidesResult
        self.acceptRideResult = acceptRideResult
        self.startRideResult = startRideResult
        self.completeRideResult = completeRideResult
    }

    /// On success, mirrors the requested `isOnline` back in the returned
    /// `User` (rather than the injected stub's fixed value) — otherwise
    /// callers that toggle offline would see a stale `isOnline: true` from
    /// the default stub and never actually observe going offline.
    func setOnlineStatus(_ isOnline: Bool) async throws -> User {
        setOnlineStatusCallCount += 1
        lastRequestedIsOnline = isOnline
        let user = try setOnlineStatusResult.get()
        return User(id: user.id, username: user.username, email: user.email,
                   phoneNumber: user.phoneNumber, profileImageURL: user.profileImageURL,
                   createdAt: user.createdAt, driverProfile: DriverProfile(isOnline: isOnline))
    }

    func fetchAvailableRides(near coordinate: Coordinate) async throws -> [Trip] {
        fetchAvailableRidesCallCount += 1
        lastRequestedCoordinate = coordinate
        return try fetchAvailableRidesResult.get()
    }

    func acceptRide(id: String) async throws -> Trip {
        acceptRideCallCount += 1
        lastAcceptedRideID = id
        return try acceptRideResult.get()
    }

    func startRide(id: String) async throws -> Trip {
        startRideCallCount += 1
        lastStartedRideID = id
        return try startRideResult.get()
    }

    func completeRide(id: String) async throws -> Trip {
        completeRideCallCount += 1
        lastCompletedRideID = id
        return try completeRideResult.get()
    }
}

extension User {
    static var driverStub: User {
        User(id: "driver-1", username: "Driver", email: "driver@x.com", phoneNumber: "+2011",
             profileImageURL: nil, createdAt: Date(timeIntervalSince1970: 0),
             driverProfile: DriverProfile(isOnline: true))
    }
}

extension Trip {
    static var driverStub: Trip {
        Trip(id: "ride-1", riderID: "rider-1", driverID: "driver-1", status: .accepted,
             pickupCoordinate: Coordinate(latitude: 30.0, longitude: 31.0),
             destinationCoordinate: Coordinate(latitude: 30.1, longitude: 31.1),
             tier: .economy, fare: 25.0,
             requestedAt: Date(timeIntervalSince1970: 0), acceptedAt: Date(timeIntervalSince1970: 1),
             completedAt: nil, cancelledAt: nil)
    }

    static var driverStubOngoing: Trip {
        Trip(id: "ride-1", riderID: "rider-1", driverID: "driver-1", status: .ongoing,
             pickupCoordinate: Coordinate(latitude: 30.0, longitude: 31.0),
             destinationCoordinate: Coordinate(latitude: 30.1, longitude: 31.1),
             tier: .economy, fare: 25.0,
             requestedAt: Date(timeIntervalSince1970: 0), acceptedAt: Date(timeIntervalSince1970: 1),
             completedAt: nil, cancelledAt: nil)
    }
}
