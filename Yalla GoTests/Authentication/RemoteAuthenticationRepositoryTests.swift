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
        let tokenStorage = SpyTokenStorage()
        let sut = RemoteAuthenticationRepository(client: client, tokenStorage: tokenStorage)

        let user = await sut.currentUser()

        #expect(user == nil)
        #expect(client.capturedEndpoint == nil) // never even attempted the call
    }

    @Test func currentUserClearsTokenAndReturnsNilOn401() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let tokenStorage = SpyTokenStorage()
        tokenStorage.stubbedToken = "expired-token"
        let sut = RemoteAuthenticationRepository(client: client, tokenStorage: tokenStorage)

        let user = await sut.currentUser()

        #expect(user == nil)
        #expect(tokenStorage.deleteCallCount == 1)
    }

    @Test func currentUserKeepsTokenOnTransientFailure() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.noInternet)
        let tokenStorage = SpyTokenStorage()
        tokenStorage.stubbedToken = "still-valid-token"
        let sut = RemoteAuthenticationRepository(client: client, tokenStorage: tokenStorage)

        let user = await sut.currentUser()

        #expect(user == nil) // transient failure — can't confirm the user, but...
        #expect(tokenStorage.deleteCallCount == 0) // ...the token is not thrown away
    }

    @Test func logoutSucceedsAndClearsTokenWhenAlreadyExpired() async throws {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let tokenStorage = SpyTokenStorage()
        let sut = RemoteAuthenticationRepository(client: client, tokenStorage: tokenStorage)

        try await sut.logout() // must not throw — the user is logged out either way

        #expect(tokenStorage.deleteCallCount == 1)
    }

    @Test func logoutSucceedsOn204() async throws {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.noData)
        let tokenStorage = SpyTokenStorage()
        let sut = RemoteAuthenticationRepository(client: client, tokenStorage: tokenStorage)

        try await sut.logout()

        #expect(tokenStorage.deleteCallCount == 1)
    }
}
