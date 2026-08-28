//
//  DriverDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the `/drivers` endpoints. `PATCH /drivers/me/status`
/// and `GET /rides/available` reuse `AuthDTO.UserResponse` and
/// `RideDTO.RideResponse` respectively — both endpoints return exactly those
/// shapes, so no duplicate DTO is declared here for either response.
enum DriverDTO {
    /// Request body for PATCH /drivers/me/status.
    struct StatusUpdateRequest: Encodable {
        let isOnline: Bool
    }

    /// Request body for PATCH /drivers/me/vehicle — partial update, every
    /// field optional, only provided (non-nil) ones change. Matches the
    /// backend's DriverVehicleUpdateRequest exactly.
    struct VehicleUpdateRequest: Encodable {
        let vehicleType: String?
        let vehicleColor: String?
        let licensePlate: String?
        let scooterType: String?  // → scooter_type via convertToSnakeCase
    }
}
