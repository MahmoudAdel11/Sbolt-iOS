//
//  RetryingAPIClient.swift
//  Yalla Go
//

import Foundation

/// Decorator that retries a request when it fails with a genuinely
/// transient error — timeout, no internet, or a 5xx server error. Never
/// retries 4xx (the request itself is wrong/rejected; repeating it changes
/// nothing) or any other error.
///
/// Policy: 3 attempts total (1 original + 2 retries), with backoff of
/// 0.5s then 1.5s between attempts — short enough not to stall the UI
/// noticeably, long enough to ride out a brief blip. If a `reachability`
/// monitor is supplied and reports the device is offline, retries stop
/// immediately instead of burning the remaining attempts against a known-dead
/// connection — the offline banner (driven by the same kind of monitor)
/// covers communicating that state to the user.
final class RetryingAPIClient: APIClient {

    static let defaultDelays: [TimeInterval] = [0.5, 1.5]

    private let inner: any APIClient
    private let maxAttempts: Int
    private let delays: [TimeInterval]
    private let sleeper: any RetryDelaying
    private let reachability: (any NetworkReachabilityMonitoring)?

    init(inner: any APIClient,
         maxAttempts: Int = 3,
         delays: [TimeInterval] = RetryingAPIClient.defaultDelays,
         sleeper: any RetryDelaying = TaskSleeper(),
         reachability: (any NetworkReachabilityMonitoring)? = nil) {
        self.inner = inner
        self.maxAttempts = maxAttempts
        self.delays = delays
        self.sleeper = sleeper
        self.reachability = reachability
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var attempt = 0
        while true {
            do {
                return try await inner.send(endpoint)
            } catch {
                attempt += 1
                let isLastAttempt = attempt >= maxAttempts
                guard !isLastAttempt, isRetryable(error), isWorthRetrying else {
                    throw error
                }
                let delay = delays[min(attempt - 1, delays.count - 1)]
                try await sleeper.sleep(delay)
            }
        }
    }

    private var isWorthRetrying: Bool {
        reachability?.isConnected ?? true
    }

    private func isRetryable(_ error: Error) -> Bool {
        switch error {
        case NetworkError.timeout, NetworkError.noInternet:
            return true
        case let NetworkError.serverError(statusCode, _):
            return (500...599).contains(statusCode)
        default:
            return false
        }
    }
}
