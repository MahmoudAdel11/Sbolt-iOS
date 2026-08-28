
//
//  ProfileDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the profile endpoints.
enum ProfileDTO {

    /// Nested on ProfileResponse — presence (non-nil) means the user has
    /// driver capability. Matches backend's DriverProfileResponse.
    struct DriverProfileResponse: Decodable {
        let isOnline: Bool
        let vehicleType: String?
        let vehicleColor: String?
        let licensePlate: String?
        let scooterType: String?
    }

    /// Response body for GET /auth/me and PATCH /users/me. Backend has no
    /// profile-image field yet, so profileImageURL is always nil here.
    struct ProfileResponse: Decodable {
        let id: String
        let fullName: String
        let email: String
        let phoneNumber: String
        let createdAt: Date
        let driverProfile: DriverProfileResponse?

        func toDomain() -> User {
            User(
                id: id,
                username: fullName,
                email: email,
                phoneNumber: phoneNumber,
                profileImageURL: nil,
                createdAt: createdAt,
                driverProfile: driverProfile.map {
                    DriverProfile(isOnline: $0.isOnline,
                                 vehicleType: $0.vehicleType,
                                 vehicleColor: $0.vehicleColor,
                                 licensePlate: $0.licensePlate,
                                 scooterType: $0.scooterType.flatMap(RideType.init(rawValue:)))
                }
            )
        }
    }

    /// Request body for PATCH /users/me. profileImageURL is intentionally
    /// omitted — the backend has no such field yet.
    struct ProfileUpdateRequest: Encodable {
        let fullName: String
        let phoneNumber: String

        init(_ update: ProfileUpdate) {
            self.fullName = update.username
            self.phoneNumber = update.phoneNumber
        }
    }
}
