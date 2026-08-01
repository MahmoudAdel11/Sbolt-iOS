
//
//  AuthDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the authentication endpoints.
/// Fill in concrete fields once the API contract is finalised.
enum AuthDTO {

    /// Response body for POST /auth/login and POST /auth/register.
    struct LoginResponse: Decodable {
        let id: String
        let username: String
        let email: String
        let phoneNumber: String
        let profileImageURLString: String?
        let accessToken: String
        let createdAt: Date

        private enum CodingKeys: String, CodingKey {
            case id, username, email, phoneNumber, accessToken, createdAt
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
