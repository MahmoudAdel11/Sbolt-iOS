
//
//  ProfileDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the profile endpoints.
enum ProfileDTO {

    /// Response body for GET /auth/me and PATCH /users/me. Backend has no
    /// profile-image field yet, so profileImageURL is always nil here.
    struct ProfileResponse: Decodable {
        let id: String
        let fullName: String
        let email: String
        let phoneNumber: String
        let createdAt: Date

        func toDomain() -> User {
            User(
                id: id,
                username: fullName,
                email: email,
                phoneNumber: phoneNumber,
                profileImageURL: nil,
                createdAt: createdAt
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
