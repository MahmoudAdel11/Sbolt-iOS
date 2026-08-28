//
//  RetryingAPIClientTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

private struct StubResponse: Codable, Equatable {
    let value: String
}

/// Fails a fixed number of times before succeeding (or fails forever if
/// `failuresBeforeSuccess` exceeds the number of calls made).
private final class FlakyAPIClient: APIClient {
    private(set) var callCount = 0
    private let error: Error
    private let failuresBeforeSuccess: Int

    init(error: Error, failuresBeforeSuccess: Int) {
        self.error = error
        self.failuresBeforeSuccess = failuresBeforeSuccess
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        callCount += 1
        if callCount <= failuresBeforeSuccess {
            throw error
        }
        let data = try JSONEncoder().encode(StubResponse(value: "ok"))
        return try JSONDecoder().decode(T.self, from: data)
    }
}

/// Records requested delays instead of actually sleeping.
private final class SpyDelaying: RetryDelaying {
    private(set) var recordedDelays: [TimeInterval] = []
    func sleep(_ seconds: TimeInterval) async throws {
        recordedDelays.append(seconds)
    }
}

private final class FixedReachability: NetworkReachabilityMonitoring {
    let isConnected: Bool
    var isConnectedPublisher: AnyPublisher<Bool, Never> { Just(isConnected).eraseToAnyPublisher() }
    init(isConnected: Bool) { self.isConnected = isConnected }
}

import Combine

struct RetryingAPIClientTests {

    @Test func retriesTransientErrorAndEventuallySucceeds() async throws {
        let inner = FlakyAPIClient(error: NetworkError.timeout, failuresBeforeSuccess: 2)
        let delaying = SpyDelaying()
        let sut = RetryingAPIClient(inner: inner, sleeper: delaying)

        let result: StubResponse = try await sut.send(Endpoint(path: "/x", method: .get))

        #expect(result == StubResponse(value: "ok"))
        #expect(inner.callCount == 3) // 1 original + 2 retries
        #expect(delaying.recordedDelays == [0.5, 1.5])
    }

    @Test func retries5xxServerError() async throws {
        let inner = FlakyAPIClient(error: NetworkError.serverError(statusCode: 503, message: nil), failuresBeforeSuccess: 1)
        let delaying = SpyDelaying()
        let sut = RetryingAPIClient(inner: inner, sleeper: delaying)

        let result: StubResponse = try await sut.send(Endpoint(path: "/x", method: .get))

        #expect(result == StubResponse(value: "ok"))
        #expect(inner.callCount == 2)
    }

    @Test func neverRetries4xxErrors() async {
        let inner = FlakyAPIClient(error: NetworkError.notFound, failuresBeforeSuccess: .max)
        let delaying = SpyDelaying()
        let sut = RetryingAPIClient(inner: inner, sleeper: delaying)

        await #expect(throws: NetworkError.self) {
            let _: StubResponse = try await sut.send(Endpoint(path: "/x", method: .get))
        }
        #expect(inner.callCount == 1) // no retry attempted
        #expect(delaying.recordedDelays.isEmpty)
    }

    @Test func neverRetriesUnauthorized() async {
        let inner = FlakyAPIClient(error: NetworkError.unauthorized, failuresBeforeSuccess: .max)
        let sut = RetryingAPIClient(inner: inner, sleeper: SpyDelaying())

        await #expect(throws: NetworkError.self) {
            let _: StubResponse = try await sut.send(Endpoint(path: "/x", method: .get))
        }
        #expect(inner.callCount == 1)
    }

    @Test func exhaustsMaxAttemptsAndThrowsLastError() async {
        let inner = FlakyAPIClient(error: NetworkError.timeout, failuresBeforeSuccess: .max)
        let delaying = SpyDelaying()
        let sut = RetryingAPIClient(inner: inner, sleeper: delaying)

        await #expect(throws: NetworkError.self) {
            let _: StubResponse = try await sut.send(Endpoint(path: "/x", method: .get))
        }
        #expect(inner.callCount == 3) // 1 original + 2 retries, then gives up
        #expect(delaying.recordedDelays == [0.5, 1.5])
    }

    @Test func doesNotRetryWhenKnownOffline() async {
        let inner = FlakyAPIClient(error: NetworkError.timeout, failuresBeforeSuccess: .max)
        let sut = RetryingAPIClient(inner: inner, sleeper: SpyDelaying(), reachability: FixedReachability(isConnected: false))

        await #expect(throws: NetworkError.self) {
            let _: StubResponse = try await sut.send(Endpoint(path: "/x", method: .get))
        }
        #expect(inner.callCount == 1) // stops immediately, doesn't burn the retry budget
    }

    @Test func retriesNormallyWhenReachabilityReportsConnected() async throws {
        let inner = FlakyAPIClient(error: NetworkError.timeout, failuresBeforeSuccess: 1)
        let sut = RetryingAPIClient(inner: inner, sleeper: SpyDelaying(), reachability: FixedReachability(isConnected: true))

        let result: StubResponse = try await sut.send(Endpoint(path: "/x", method: .get))
        #expect(result == StubResponse(value: "ok"))
        #expect(inner.callCount == 2)
    }
}
