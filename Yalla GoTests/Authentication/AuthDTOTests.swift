//
//  AuthDTOTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

struct AuthDTOTests {

    // MARK: - RegisterRequest encoding

    @Test func registerRequestEncodesRegisterAsDriverTrue() throws {
        let request = AuthDTO.RegisterRequest(
            fullName: "Jane", email: "jane@example.com", phoneNumber: "+201000000000",
            password: "secret123", registerAsDriver: true, scooterType: "comfort"
        )
        let data = try JSONEncoder.backend.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["register_as_driver"] as? Bool == true)
    }

    @Test func registerRequestEncodesRegisterAsDriverFalse() throws {
        let request = AuthDTO.RegisterRequest(
            fullName: "Jane", email: "jane@example.com", phoneNumber: "+201000000000",
            password: "secret123", registerAsDriver: false, scooterType: nil
        )
        let data = try JSONEncoder.backend.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["register_as_driver"] as? Bool == false)
    }

    @Test func registerRequestEncodesScooterTypeSnakeCase() throws {
        let request = AuthDTO.RegisterRequest(
            fullName: "Jane", email: "jane@example.com", phoneNumber: "+201000000000",
            password: "secret123", registerAsDriver: true, scooterType: "premium"
        )
        let data = try JSONEncoder.backend.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["scooter_type"] as? String == "premium")
    }

    @Test func registerRequestOmitsScooterTypeKeyWhenNil() throws {
        let request = AuthDTO.RegisterRequest(
            fullName: "Jane", email: "jane@example.com", phoneNumber: "+201000000000",
            password: "secret123", registerAsDriver: false, scooterType: nil
        )
        let data = try JSONEncoder.backend.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Swift's JSONEncoder omits `nil` Optional fields entirely rather than
        // encoding an explicit `null` - confirm the key isn't present at all.
        #expect(json["scooter_type"] == nil)
    }

    // MARK: - UserResponse decoding

    private func userJSON(driverProfileJSON: String) -> Data {
        let json = """
        {
            "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            "email": "test@yallago.com",
            "full_name": "Test User",
            "phone_number": "+201234567890",
            "is_active": true,
            "driver_profile": \(driverProfileJSON),
            "created_at": "2026-01-01T00:00:00.000000Z"
        }
        """
        return Data(json.utf8)
    }

    @Test func userResponseDecodesNullDriverProfileAsNil() throws {
        let dto = try JSONDecoder.backend.decode(
            AuthDTO.UserResponse.self, from: userJSON(driverProfileJSON: "null")
        )

        #expect(dto.driverProfile == nil)
        #expect(dto.toDomain().driverProfile == nil)
    }

    @Test func userResponseDecodesPresentDriverProfile() throws {
        let dto = try JSONDecoder.backend.decode(
            AuthDTO.UserResponse.self,
            from: userJSON(driverProfileJSON: #"{"is_online": true}"#)
        )

        #expect(dto.driverProfile?.isOnline == true)
        #expect(dto.toDomain().driverProfile == DriverProfile(isOnline: true))
    }

    @Test func userResponseDecodesOfflineDriverProfile() throws {
        let dto = try JSONDecoder.backend.decode(
            AuthDTO.UserResponse.self,
            from: userJSON(driverProfileJSON: #"{"is_online": false}"#)
        )

        #expect(dto.toDomain().driverProfile == DriverProfile(isOnline: false))
    }

    // MARK: - LoginResponse decoding

    @Test func loginResponseDecodesAccessAndRefreshToken() throws {
        let json = Data("""
        {"access_token": "access-abc", "refresh_token": "refresh-xyz", "token_type": "bearer"}
        """.utf8)

        let dto = try JSONDecoder.backend.decode(AuthDTO.LoginResponse.self, from: json)

        #expect(dto.accessToken == "access-abc")
        #expect(dto.refreshToken == "refresh-xyz")
        #expect(dto.tokenType == "bearer")
    }

    // MARK: - RegisterResponse decoding

    @Test func registerResponseDecodesNestedUserAndBothTokens() throws {
        let json = Data("""
        {
            "user": {
                "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                "email": "jane@example.com",
                "full_name": "Jane Doe",
                "phone_number": "+201234567890",
                "created_at": "2026-01-01T00:00:00.000000Z",
                "driver_profile": null
            },
            "access_token": "access-abc",
            "refresh_token": "refresh-xyz",
            "token_type": "bearer"
        }
        """.utf8)

        let dto = try JSONDecoder.backend.decode(AuthDTO.RegisterResponse.self, from: json)

        #expect(dto.user.email == "jane@example.com")
        #expect(dto.accessToken == "access-abc")
        #expect(dto.refreshToken == "refresh-xyz")
        #expect(dto.user.toDomain().email == "jane@example.com")
    }

    // MARK: - RefreshRequest encoding / RefreshResponse decoding

    @Test func refreshRequestEncodesRefreshTokenSnakeCase() throws {
        let request = AuthDTO.RefreshRequest(refreshToken: "refresh-xyz")
        let data = try JSONEncoder.backend.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["refresh_token"] as? String == "refresh-xyz")
    }

    @Test func refreshResponseDecodesAccessTokenOnly() throws {
        let json = Data(#"{"access_token": "new-access-token", "token_type": "bearer"}"#.utf8)

        let dto = try JSONDecoder.backend.decode(AuthDTO.RefreshResponse.self, from: json)

        #expect(dto.accessToken == "new-access-token")
        #expect(dto.tokenType == "bearer")
    }
}
