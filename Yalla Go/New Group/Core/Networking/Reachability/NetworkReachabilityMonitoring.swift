//
//  NetworkReachabilityMonitoring.swift
//  Yalla Go
//

import Foundation
import Combine

/// Reports device-level connectivity. Abstracted behind a protocol so
/// `RetryingAPIClient` and any UI observer never touch `NWPathMonitor`
/// directly and can be tested with a fake implementation.
protocol NetworkReachabilityMonitoring: AnyObject {
    /// Best-known connectivity state, safe to read synchronously from any thread.
    var isConnected: Bool { get }
    /// Emits every time `isConnected` changes.
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
}
