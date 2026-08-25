//
//  KeychainTokenRefresherTests.swift
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

private final class InMemoryTokenStorage: TokenStorage {
    private(set) var savedTokens: [String] = []
    private(set) var deleteCallCount = 0
    var stubbedToken: String?

    func save(_ token: String) { savedTokens.append(token); stubbedToken = token }
    func retrieve() -> String? { stubbedToken }
    func delete() { deleteCallCount += 1; stubbedToken = nil }
}

struct KeychainTokenRefresherTests {

    @Test func returnsNilWithoutNetworkCallWhenNoRefreshTokenStored() async {
        let client = StubAPIClient()
        let refreshTokenStorage = InMemoryTokenStorage()
        let sut = KeychainTokenRefresher(
            client: client,
            accessTokenStorage: InMemoryTokenStorage(),
            refreshTokenStorage: refreshTokenStorage
        )

        let newToken = await sut.refreshAccessToken()

        #expect(newToken == nil)
        #expect(client.capturedEndpoint == nil)
    }

    @Test func sendsStoredRefreshTokenAndSavesNewAccessTokenOnSuccess() async {
        let client = StubAPIClient()
        client.result = .success(Data("""
        {"access_token": "new-access-token", "token_type": "bearer"}
        """.utf8))
        let refreshTokenStorage = InMemoryTokenStorage()
        refreshTokenStorage.stubbedToken = "stored-refresh-token"
        let accessTokenStorage = InMemoryTokenStorage()
        let sut = KeychainTokenRefresher(
            client: client, accessTokenStorage: accessTokenStorage, refreshTokenStorage: refreshTokenStorage
        )

        let newToken = await sut.refreshAccessToken()

        #expect(newToken == "new-access-token")
        #expect(accessTokenStorage.savedTokens == ["new-access-token"])
        #expect(client.capturedEndpoint?.path == "/auth/refresh")
        #expect(client.capturedEndpoint?.method == .post)

        let body = try? JSONSerialization.jsonObject(with: client.capturedEndpoint?.body ?? Data()) as? [String: Any]
        #expect(body?["refresh_token"] as? String == "stored-refresh-token")
    }

    @Test func returnsNilAndDoesNotSaveWhenBackendRejectsRefreshToken() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let refreshTokenStorage = InMemoryTokenStorage()
        refreshTokenStorage.stubbedToken = "expired-refresh-token"
        let accessTokenStorage = InMemoryTokenStorage()
        let sut = KeychainTokenRefresher(
            client: client, accessTokenStorage: accessTokenStorage, refreshTokenStorage: refreshTokenStorage
        )

        let newToken = await sut.refreshAccessToken()

        #expect(newToken == nil)
        #expect(accessTokenStorage.savedTokens.isEmpty)
    }
}
