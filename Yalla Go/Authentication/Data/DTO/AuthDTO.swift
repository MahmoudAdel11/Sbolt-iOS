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
/// POST /auth/login    →  LoginResponse     ({access_token, refresh_token, token_type} — no user fields)
/// POST /auth/register →  RegisterResponse  ({user, access_token, refresh_token, token_type})
/// POST /auth/refresh  →  RefreshResponse   ({access_token, token_type} — sliding renewal, refresh_token unchanged)
/// GET  /auth/me        →  UserResponse      (user fields only, no token)
/// POST /auth/logout    →  204 No Content
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
        let registerAsDriver: Bool // → register_as_driver via convertToSnakeCase
    }

    struct RefreshRequest: Encodable {
        let refreshToken: String  // → refresh_token via convertToSnakeCase
    }

    // MARK: - Response bodies

    /// Response for POST /auth/login. Still no user fields — the caller must
    /// follow up with GET /auth/me — but now carries both tokens.
    struct LoginResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let tokenType: String
    }

    /// Response for POST /auth/register. Unlike login, the backend returns the
    /// full user profile directly here, so no follow-up GET /auth/me is needed.
    struct RegisterResponse: Decodable {
        let user: UserResponse
        let accessToken: String
        let refreshToken: String
        let tokenType: String
    }

    /// Response for POST /auth/refresh. Sliding renewal only extends the
    /// existing refresh token's lifetime server-side — it is never reissued,
    /// so only a new access_token comes back.
    struct RefreshResponse: Decodable {
        let accessToken: String
        let tokenType: String
    }

    /// Nested on UserResponse — presence (non-nil) means the user has driver
    /// capability. Matches backend's DriverProfileResponse { is_online }.
    struct DriverProfileResponse: Decodable {
        let isOnline: Bool
    }

    /// Response for GET /auth/me, and nested inside RegisterResponse — user
    /// fields only, no token. Backend has no profile-image field yet, so
    /// profileImageURL is always nil here.
    struct UserResponse: Decodable {
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
                driverProfile: driverProfile.map { DriverProfile(isOnline: $0.isOnline) }
            )
        }
    }
}
