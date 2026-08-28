//
//  RemoteProfileRepositoryTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

private final class StubAPIClient: APIClient {
    enum StubResult {
        case success(Data)
        case failure(Error)
    }

    var result: StubResult = .failure(NetworkError.unknown("unset"))
    private(set) var capturedEndpoint: Endpoint?

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        capturedEndpoint = endpoint
        switch result {
        case .success(let data):
            return try JSONDecoder.backend.decode(T.self, from: data)
        case .failure(let error):
            throw error
        }
    }
}

private func profileJSON(fullName: String = "Test User", phoneNumber: String = "+201234567890") -> Data {
    let json = """
    {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "email": "test@yallago.com",
        "full_name": "\(fullName)",
        "phone_number": "\(phoneNumber)",
        "is_active": true,
        "created_at": "2026-01-01T00:00:00.000000Z"
    }
    """
    return Data(json.utf8)
}

struct RemoteProfileRepositoryTests {

    @Test func getProfileSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(profileJSON())
        let sut = RemoteProfileRepository(client: client)

        let profile = try await sut.getProfile()

        #expect(profile.username == "Test User")
        #expect(profile.phoneNumber == "+201234567890")
        #expect(client.capturedEndpoint?.path == "/auth/me")
        #expect(client.capturedEndpoint?.method == .get)
    }

    @Test func getProfileMapsUnauthorizedToSessionExpired() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let sut = RemoteProfileRepository(client: client)

        await #expect(throws: ProfileError.sessionExpired) {
            _ = try await sut.getProfile()
        }
    }

    @Test func getProfileMapsForbiddenToProfileUnavailable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.forbidden)
        let sut = RemoteProfileRepository(client: client)

        await #expect(throws: ProfileError.profileUnavailable) {
            _ = try await sut.getProfile()
        }
    }

    @Test func updateProfileMapsUnauthorizedToSessionExpired() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let sut = RemoteProfileRepository(client: client)
        let update = ProfileUpdate(username: "Name", phoneNumber: "+201111111111", profileImageURL: nil)

        await #expect(throws: ProfileError.sessionExpired) {
            _ = try await sut.updateProfile(update)
        }
    }

    @Test func getProfileMapsNoInternetToNetworkUnavailable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.noInternet)
        let sut = RemoteProfileRepository(client: client)

        await #expect(throws: ProfileError.networkUnavailable) {
            _ = try await sut.getProfile()
        }
    }

    @Test func updateProfileSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(profileJSON(fullName: "Updated Name", phoneNumber: "+209999999999"))
        let sut = RemoteProfileRepository(client: client)
        let update = ProfileUpdate(username: "Updated Name", phoneNumber: "+209999999999", profileImageURL: nil)

        let profile = try await sut.updateProfile(update)

        #expect(profile.username == "Updated Name")
        #expect(profile.phoneNumber == "+209999999999")
        #expect(client.capturedEndpoint?.path == "/users/me")
        #expect(client.capturedEndpoint?.method == .patch)

        let body = try #require(client.capturedEndpoint?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["full_name"] as? String == "Updated Name")
        #expect(json["phone_number"] as? String == "+209999999999")
    }

    @Test func updateProfileMapsConflictToUpdateFailed() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: nil))
        let sut = RemoteProfileRepository(client: client)
        let update = ProfileUpdate(username: "Name", phoneNumber: "+201111111111", profileImageURL: nil)

        await #expect(throws: ProfileError.updateFailed) {
            _ = try await sut.updateProfile(update)
        }
    }

    @Test func unclassifiedErrorMapsToUnknown() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.requestCancelled)
        let sut = RemoteProfileRepository(client: client)

        await #expect(throws: ProfileError.unknown) {
            _ = try await sut.getProfile()
        }
    }
}
