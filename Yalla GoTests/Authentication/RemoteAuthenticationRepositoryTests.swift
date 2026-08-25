//
//  RemoteAuthenticationRepositoryTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

private final class StubAPIClient: APIClient {
    enum StubResult {
        case success(Data)
        case failure(Error)
    }

    /// Single-response tests set `result`; multi-call tests (e.g. login's
    /// login-then-me) set `results` and each call consumes the next one.
    var result: StubResult = .failure(NetworkError.unknown("unset"))
    var results: [StubResult] = []
    private(set) var capturedEndpoint: Endpoint?
    private(set) var callCount = 0

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        capturedEndpoint = endpoint
        callCount += 1
        let next = results.isEmpty ? result : results.removeFirst()
        switch next {
        case .success(let data):
            return try JSONDecoder.backend.decode(T.self, from: data)
        case .failure(let error):
            throw error
        }
    }
}

private final class SpyTokenStorage: TokenStorage {
    private(set) var savedTokens: [String] = []
    private(set) var deleteCallCount = 0
    var stubbedToken: String?

    func save(_ token: String) { savedTokens.append(token) }
    func retrieve() -> String? { stubbedToken }
    func delete() { deleteCallCount += 1 }
}

/// Covers the session-expiry paths this sprint's audit called out:
/// currentUser()/logout() encountering a 401 mid-session (as opposed to
/// login's own 401, which means invalid credentials, not session expiry).
struct RemoteAuthenticationRepositoryTests {

    @Test func currentUserReturnsNilWithoutNetworkCallWhenNoTokenStored() async {
        let client = StubAPIClient()
        let accessTokenStorage = SpyTokenStorage()
        let sut = RemoteAuthenticationRepository(
            client: client, accessTokenStorage: accessTokenStorage, refreshTokenStorage: SpyTokenStorage()
        )

        let user = await sut.currentUser()

        #expect(user == nil)
        #expect(client.capturedEndpoint == nil) // never even attempted the call
    }

    @Test func currentUserClearsBothTokensAndReturnsNilOn401() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let accessTokenStorage = SpyTokenStorage()
        accessTokenStorage.stubbedToken = "expired-token"
        let refreshTokenStorage = SpyTokenStorage()
        let sut = RemoteAuthenticationRepository(
            client: client, accessTokenStorage: accessTokenStorage, refreshTokenStorage: refreshTokenStorage
        )

        let user = await sut.currentUser()

        #expect(user == nil)
        #expect(accessTokenStorage.deleteCallCount == 1)
        #expect(refreshTokenStorage.deleteCallCount == 1)
    }

    @Test func currentUserKeepsTokenOnTransientFailure() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.noInternet)
        let accessTokenStorage = SpyTokenStorage()
        accessTokenStorage.stubbedToken = "still-valid-token"
        let sut = RemoteAuthenticationRepository(
            client: client, accessTokenStorage: accessTokenStorage, refreshTokenStorage: SpyTokenStorage()
        )

        let user = await sut.currentUser()

        #expect(user == nil) // transient failure — can't confirm the user, but...
        #expect(accessTokenStorage.deleteCallCount == 0) // ...the token is not thrown away
    }

    @Test func logoutSucceedsAndClearsBothTokensWhenAlreadyExpired() async throws {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let accessTokenStorage = SpyTokenStorage()
        let refreshTokenStorage = SpyTokenStorage()
        let sut = RemoteAuthenticationRepository(
            client: client, accessTokenStorage: accessTokenStorage, refreshTokenStorage: refreshTokenStorage
        )

        try await sut.logout() // must not throw — the user is logged out either way

        #expect(accessTokenStorage.deleteCallCount == 1)
        #expect(refreshTokenStorage.deleteCallCount == 1)
    }

    @Test func logoutSucceedsOn204() async throws {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.noData)
        let accessTokenStorage = SpyTokenStorage()
        let refreshTokenStorage = SpyTokenStorage()
        let sut = RemoteAuthenticationRepository(
            client: client, accessTokenStorage: accessTokenStorage, refreshTokenStorage: refreshTokenStorage
        )

        try await sut.logout()

        #expect(accessTokenStorage.deleteCallCount == 1)
        #expect(refreshTokenStorage.deleteCallCount == 1)
    }

    // MARK: - register()

    @Test func registerSavesBothTokensAndReturnsUserWithoutFollowUpLoginCall() async throws {
        let client = StubAPIClient()
        client.result = .success(Data("""
        {
            "user": {
                "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                "email": "jane@example.com",
                "full_name": "Jane Doe",
                "phone_number": "+201234567890",
                "created_at": "2026-01-01T00:00:00.000000Z",
                "driver_profile": null
            },
            "access_token": "new-access-token",
            "refresh_token": "new-refresh-token",
            "token_type": "bearer"
        }
        """.utf8))
        let accessTokenStorage = SpyTokenStorage()
        let refreshTokenStorage = SpyTokenStorage()
        let sut = RemoteAuthenticationRepository(
            client: client, accessTokenStorage: accessTokenStorage, refreshTokenStorage: refreshTokenStorage
        )

        let user = try await sut.register(
            RegistrationDetails(
                username: "Jane Doe", email: "jane@example.com", phoneNumber: "+201234567890",
                password: "supersecret123", registerAsDriver: false
            )
        )

        #expect(user.email == "jane@example.com")
        #expect(accessTokenStorage.savedTokens == ["new-access-token"])
        #expect(refreshTokenStorage.savedTokens == ["new-refresh-token"])
        // A single call — /auth/register only. No follow-up /auth/login or
        // /auth/me: the register response already carries the user + tokens.
        #expect(client.callCount == 1)
    }

    // MARK: - login()

    @Test func loginSavesBothTokens() async throws {
        let client = StubAPIClient()
        client.results = [
            .success(Data("""
            {"access_token": "new-access-token", "refresh_token": "new-refresh-token", "token_type": "bearer"}
            """.utf8)),
            .success(Data("""
            {
                "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6", "email": "jane@example.com",
                "full_name": "Jane Doe", "phone_number": "+201234567890",
                "created_at": "2026-01-01T00:00:00.000000Z", "driver_profile": null
            }
            """.utf8)),
        ]
        let accessTokenStorage = SpyTokenStorage()
        let refreshTokenStorage = SpyTokenStorage()
        let sut = RemoteAuthenticationRepository(
            client: client, accessTokenStorage: accessTokenStorage, refreshTokenStorage: refreshTokenStorage
        )

        _ = try await sut.login(email: "jane@example.com", password: "supersecret123")

        #expect(accessTokenStorage.savedTokens == ["new-access-token"])
        #expect(refreshTokenStorage.savedTokens == ["new-refresh-token"])
    }
}
