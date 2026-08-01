
//
//  ProfileDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the profile endpoints.
/// Fill in concrete fields once the API contract is finalised.
enum ProfileDTO {

    /// Response body for GET /profile and PATCH /profile.
    struct ProfileResponse: Decodable {
        let id: String
        let username: String
        let email: String
        let phoneNumber: String
        let profileImageURLString: String?
        let createdAt: Date

        private enum CodingKeys: String, CodingKey {
            case id, username, email, phoneNumber, createdAt
            case profileImageURLString = "profileImageURL"
        }

        func toDomain() -> User {
            User(
                id: id,
                username: username,
                email: email,
                phoneNumber: phoneNumber,
                profileImageURL: profileImageURLString.flatMap(URL.init(string:)),
                createdAt: createdAt
            )
        }
    }
}
