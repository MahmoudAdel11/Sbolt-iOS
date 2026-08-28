//
//  RetryDelaying.swift
//  Yalla Go
//

import Foundation

/// Abstracts the actual wait between retry attempts so `RetryingAPIClient`
/// can be unit-tested without real delays.
protocol RetryDelaying {
    func sleep(_ seconds: TimeInterval) async throws
}

/// Production implementation — a real, cancellation-aware delay.
struct TaskSleeper: RetryDelaying {
    func sleep(_ seconds: TimeInterval) async throws {
        guard seconds > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
