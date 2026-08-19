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
            password: "secret123", registerAsDriver: true
        )
        let data = try JSONEncoder.backend.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["register_as_driver"] as? Bool == true)
    }

    @Test func registerRequestEncodesRegisterAsDriverFalse() throws {
        let request = AuthDTO.RegisterRequest(
            fullName: "Jane", email: "jane@example.com", phoneNumber: "+201000000000",
            password: "secret123", registerAsDriver: false
        )
        let data = try JSONEncoder.backend.encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["register_as_driver"] as? Bool == false)
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
}
