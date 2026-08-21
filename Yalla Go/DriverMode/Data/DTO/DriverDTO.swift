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
}
