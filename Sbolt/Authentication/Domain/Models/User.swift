//
//  User.swift
//  Yalla Go
//

import Foundation

/// Authenticated user in the domain layer. Backend-agnostic: it contains only
/// what the app needs today, independent of any API/DTO shape.
struct User: Identifiable, Equatable {
    let id: String
    let username: String
    let email: String
    let phoneNumber: String
    let profileImageURL: URL?
    let createdAt: Date
    /// `nil` when the user has no driver capability — the sole source of
    /// truth for "is this user a driver". A user can be a rider and a driver
    /// simultaneously; this is additive, never mutually exclusive with being
    /// a rider.
    let driverProfile: DriverProfile?
}

/// A user's driver-specific state. Presence alone (a non-nil `User.driverProfile`)
/// means the user has driver capability — there is no separate role flag.
struct DriverProfile: Equatable {
    let isOnline: Bool
    /// Free-text, driver-declared vehicle details — `nil` until the driver
    /// fills them in via the vehicle settings screen (`PATCH /drivers/me/vehicle`).
    let vehicleType: String?
    let vehicleColor: String?
    let licensePlate: String?
    /// The tier of scooter this driver can operate — reuses `RideType` (see
    /// its own doc comment: a driver's capability and a ride's tier are the
    /// same three-tier scale). `nil` for drivers who registered before this
    /// field existed, or who haven't set it yet via vehicle settings.
    let scooterType: RideType?

    init(isOnline: Bool,
         vehicleType: String? = nil,
         vehicleColor: String? = nil,
         licensePlate: String? = nil,
         scooterType: RideType? = nil) {
        self.isOnline = isOnline
        self.vehicleType = vehicleType
        self.vehicleColor = vehicleColor
        self.licensePlate = licensePlate
        self.scooterType = scooterType
    }
}
