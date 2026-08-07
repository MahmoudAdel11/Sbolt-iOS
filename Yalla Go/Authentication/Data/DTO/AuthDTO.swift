//
//  AuthDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the Yalla Go authentication endpoints.
///
/// All snake_case ↔ camelCase mapping is handled automatically by
/// `JSONDecoder.backend` (`convertFromSnakeCase`) and `JSONEncoder.backend`
/// (`convertToSnakeCase`). No manual `CodingKeys` needed unless a field name
/// deviates from the convention.
///
/// Confirmed backend response shape (FastAPI / JWT):
///
/// POST /auth/login  →  LoginResponse  (token only, no user fields)
/// POST /auth/register  →  UserResponse  (created user, no token)
/// GET  /auth/me  →  UserResponse  (user fields only, no token)
/// POST /auth/logout  →  204 No Content
enum AuthDTO {

    // MARK: - Request bodies

    struct LoginRequest: Encodable {
        let email: String
        let password: String
    }

    struct RegisterRequest: Encodable {
        let fullName: String      // → full_name via convertToSnakeCase
        let email: String
        let phoneNumber: String   // → phone_number via convertToSnakeCase
        let password: String
    }

    // MARK: - Response bodies

    /// Response for POST /auth/login. The backend returns only the token —
    /// no user fields — so the caller must follow up with GET /auth/me.
    struct LoginResponse: Decodable {
        let accessToken: String
        let tokenType: String
    }

    /// Response for GET /auth/me and POST /auth/register — user fields only,
    /// no token. Backend has no profile-image field yet, so profileImageURL
    /// is always nil here.
    struct UserResponse: Decodable {
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
}
