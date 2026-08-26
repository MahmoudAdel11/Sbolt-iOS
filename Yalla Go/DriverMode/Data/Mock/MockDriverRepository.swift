//
//  MockDriverRepository.swift
//  Yalla Go
//

import Foundation

/// In-memory `DriverRepository` that simulates a backend while the app has
/// none. An `actor` guarantees safe access to the mutable online/available/
/// active-ride state. Mirrors the real backend's rules: `fetchAvailableRides`
/// requires the driver to be online, and accepting removes the ride from the
/// available list and becomes the driver's single active ride.
actor MockDriverRepository: DriverRepository {

    enum Behavior {
        case success
        case networkFailure
    }

    private var isOnline: Bool
    private var availableRides: [Trip]
    private var activeRide: Trip?
    private var driverUser: User
    private let behavior: Behavior
    private let artificialDelay: TimeInterval

    init(driverUser: User = MockDriverRepository.makeSampleDriverUser(),
         availableRides: [Trip] = MockDriverRepository.sampleAvailableRides(),
         behavior: Behavior = .success,
         artificialDelay: TimeInterval = 0.2) {
        self.driverUser = driverUser
        self.isOnline = driverUser.driverProfile?.isOnline ?? false
        self.availableRides = availableRides
        self.behavior = behavior
        self.artificialDelay = artificialDelay
    }

    func setOnlineStatus(_ isOnline: Bool) async throws -> User {
        await simulateNetworkDelay()
        guard behavior == .success else { throw DriverError.networkUnavailable }
        self.isOnline = isOnline
        driverUser = User(id: driverUser.id, username: driverUser.username, email: driverUser.email,
                          phoneNumber: driverUser.phoneNumber, profileImageURL: driverUser.profileImageURL,
                          createdAt: driverUser.createdAt, driverProfile: DriverProfile(isOnline: isOnline))
        return driverUser
    }

    func fetchAvailableRides(near coordinate: Coordinate) async throws -> [Trip] {
        await simulateNetworkDelay()
        guard behavior == .success else { throw DriverError.networkUnavailable }
        guard isOnline else { throw DriverError.notAuthorizedAsDriver }
        return availableRides
    }

    func acceptRide(id: String) async throws -> Trip {
        await simulateNetworkDelay()
        guard behavior == .success else { throw DriverError.networkUnavailable }
        guard let index = availableRides.firstIndex(where: { $0.id == id }) else {
            throw DriverError.rideNoLongerAvailable
        }
        let ride = availableRides.remove(at: index)
        let accepted = Trip(id: ride.id, riderID: ride.riderID, driverID: driverUser.id,
                            status: .accepted, pickupCoordinate: ride.pickupCoordinate,
                            destinationCoordinate: ride.destinationCoordinate,
                            tier: ride.tier, fare: ride.fare,
                            requestedAt: ride.requestedAt, acceptedAt: Date(),
                            completedAt: nil, cancelledAt: nil)
        activeRide = accepted
        return accepted
    }

    func startRide(id: String) async throws -> Trip {
        await simulateNetworkDelay()
        guard behavior == .success else { throw DriverError.networkUnavailable }
        guard let ride = activeRide, ride.id == id, ride.status == .accepted else {
            throw DriverError.rideNotStartable
        }
        let ongoing = Trip(id: ride.id, riderID: ride.riderID, driverID: ride.driverID,
                           status: .ongoing, pickupCoordinate: ride.pickupCoordinate,
                           destinationCoordinate: ride.destinationCoordinate,
                           tier: ride.tier, fare: ride.fare,
                           requestedAt: ride.requestedAt, acceptedAt: ride.acceptedAt,
                           completedAt: nil, cancelledAt: nil)
        activeRide = ongoing
        return ongoing
    }

    func completeRide(id: String) async throws -> Trip {
        await simulateNetworkDelay()
        guard behavior == .success else { throw DriverError.networkUnavailable }
        guard let ride = activeRide, ride.id == id else { throw DriverError.rideNotCompletable }
        // Mirrors the backend: .ongoing is now required before completion —
        // .accepted (start not yet called) is a distinguishable, recoverable error.
        guard ride.status != .accepted else { throw DriverError.rideNotStarted }
        let completed = Trip(id: ride.id, riderID: ride.riderID, driverID: ride.driverID,
                             status: .completed, pickupCoordinate: ride.pickupCoordinate,
                             destinationCoordinate: ride.destinationCoordinate,
                             tier: ride.tier, fare: ride.fare,
                             requestedAt: ride.requestedAt, acceptedAt: ride.acceptedAt,
                             completedAt: Date(), cancelledAt: nil)
        activeRide = nil
        return completed
    }

    // MARK: - Helpers

    private func simulateNetworkDelay() async {
        guard artificialDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(artificialDelay * 1_000_000_000))
    }

    static func makeSampleDriverUser() -> User {
        User(id: "mock-driver-id", username: "Mock Driver", email: "driver@yallago.com",
             phoneNumber: "+201000000001", profileImageURL: nil,
             createdAt: Date(timeIntervalSince1970: 0), driverProfile: DriverProfile(isOnline: false))
    }

    static func sampleAvailableRides() -> [Trip] {
        [
            Trip(id: "available-1", riderID: "rider-9", driverID: nil, status: .requested,
                 pickupCoordinate: Coordinate(latitude: 30.0444, longitude: 31.2357),
                 destinationCoordinate: Coordinate(latitude: 30.0614, longitude: 31.2197),
                 tier: .economy, fare: 22.0,
                 requestedAt: Date(), acceptedAt: nil, completedAt: nil, cancelledAt: nil),
            Trip(id: "available-2", riderID: "rider-10", driverID: nil, status: .requested,
                 pickupCoordinate: Coordinate(latitude: 30.0080, longitude: 31.4913),
                 destinationCoordinate: Coordinate(latitude: 29.9603, longitude: 31.2569),
                 tier: .comfort, fare: 41.0,
                 requestedAt: Date(), acceptedAt: nil, completedAt: nil, cancelledAt: nil)
        ]
    }
}
