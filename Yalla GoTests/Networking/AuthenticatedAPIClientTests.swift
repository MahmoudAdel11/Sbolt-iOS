//
//  AuthenticatedAPIClientTests.swift
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

    /// Each call consumes the next queued result; if the queue is empty, `defaultResult` is used.
    var queuedResults: [StubResult] = []
    var defaultResult: StubResult = .failure(NetworkError.unknown("unset"))
    private(set) var capturedEndpoints: [Endpoint] = []

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        capturedEndpoints.append(endpoint)
        let next = queuedResults.isEmpty ? defaultResult : queuedResults.removeFirst()
        switch next {
        case .success(let data):
            return try JSONDecoder.backend.decode(T.self, from: data)
        case .failure(let error):
            throw error
        }
    }
}

private struct StubTokenProvider: TokenProvider {
    let token: String?
    func token() async -> String? { token }
}

private final class SpyTokenRefreshing: TokenRefreshing {
    var result: String?
    private(set) var callCount = 0

    func refreshAccessToken() async -> String? {
        callCount += 1
        return result
    }
}

private struct Stub: Decodable { let value: Int }

private func stubData(_ value: Int = 1) -> Data {
    Data(#"{"value":\#(value)}"#.utf8)
}

struct AuthenticatedAPIClientTests {

    @Test func injectsAuthorizationHeaderWhenTokenAvailable() async throws {
        let inner = StubAPIClient()
        inner.defaultResult = .success(stubData())
        let sut = AuthenticatedAPIClient(
            client: inner, tokenProvider: StubTokenProvider(token: "abc123")
        )

        let _: Stub = try await sut.send(Endpoint(path: "/x", method: .get))

        #expect(inner.capturedEndpoints.first?.headers["Authorization"] == "Bearer abc123")
    }

    @Test func forwardsRequestUnmodifiedWhenNoTokenAvailable() async throws {
        let inner = StubAPIClient()
        inner.defaultResult = .success(stubData())
        let sut = AuthenticatedAPIClient(client: inner, tokenProvider: StubTokenProvider(token: nil))

        let _: Stub = try await sut.send(Endpoint(path: "/x", method: .get))

        #expect(inner.capturedEndpoints.first?.headers["Authorization"] == nil)
    }

    @Test func on401RefreshesAndRetriesOnceWithNewToken() async throws {
        let inner = StubAPIClient()
        inner.queuedResults = [.failure(NetworkError.unauthorized), .success(stubData(2))]
        let refresher = SpyTokenRefreshing()
        refresher.result = "new-access-token"
        let sut = AuthenticatedAPIClient(
            client: inner, tokenProvider: StubTokenProvider(token: "stale-token"), tokenRefresher: refresher
        )

        let result: Stub = try await sut.send(Endpoint(path: "/x", method: .get))

        #expect(result.value == 2)
        #expect(refresher.callCount == 1)
        #expect(inner.capturedEndpoints.count == 2)
        #expect(inner.capturedEndpoints[0].headers["Authorization"] == "Bearer stale-token")
        #expect(inner.capturedEndpoints[1].headers["Authorization"] == "Bearer new-access-token")
    }

    @Test func rethrowsOriginal401WhenRefreshFails() async throws {
        let inner = StubAPIClient()
        inner.defaultResult = .failure(NetworkError.unauthorized)
        let refresher = SpyTokenRefreshing()
        refresher.result = nil // no refresh token, or backend rejected it
        let sut = AuthenticatedAPIClient(
            client: inner, tokenProvider: StubTokenProvider(token: "stale-token"), tokenRefresher: refresher
        )

        await #expect(throws: NetworkError.unauthorized) {
            let _: Stub = try await sut.send(Endpoint(path: "/x", method: .get))
        }
        #expect(refresher.callCount == 1)
        // Exactly one attempt at the original request — refresh failing doesn't retry it.
        #expect(inner.capturedEndpoints.count == 1)
    }

    @Test func doesNotAttemptASecondRefreshWhenRetriedRequestAlsoGets401() async throws {
        let inner = StubAPIClient()
        inner.defaultResult = .failure(NetworkError.unauthorized) // every call 401s
        let refresher = SpyTokenRefreshing()
        refresher.result = "new-access-token" // refresh itself "succeeds"...
        let sut = AuthenticatedAPIClient(
            client: inner, tokenProvider: StubTokenProvider(token: "stale-token"), tokenRefresher: refresher
        )

        await #expect(throws: NetworkError.unauthorized) {
            let _: Stub = try await sut.send(Endpoint(path: "/x", method: .get))
        }

        // ...but the retried request 401s too (refresh token itself invalid/expired) -
        // exactly one refresh attempt, exactly two total request attempts, no infinite loop.
        #expect(refresher.callCount == 1)
        #expect(inner.capturedEndpoints.count == 2)
    }

    @Test func nonUnauthorizedErrorsAreNotIntercepted() async throws {
        let inner = StubAPIClient()
        inner.defaultResult = .failure(NetworkError.notFound)
        let refresher = SpyTokenRefreshing()
        let sut = AuthenticatedAPIClient(
            client: inner, tokenProvider: StubTokenProvider(token: "token"), tokenRefresher: refresher
        )

        await #expect(throws: NetworkError.notFound) {
            let _: Stub = try await sut.send(Endpoint(path: "/x", method: .get))
        }
        #expect(refresher.callCount == 0)
        #expect(inner.capturedEndpoints.count == 1)
    }
}
