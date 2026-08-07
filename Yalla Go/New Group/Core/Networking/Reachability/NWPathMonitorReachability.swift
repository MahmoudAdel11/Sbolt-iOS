//
//  NWPathMonitorReachability.swift
//  Yalla Go
//

import Foundation
import Network
import Combine

/// `NetworkReachabilityMonitoring` backed by `Network.framework`'s `NWPathMonitor`.
/// Starts monitoring immediately on init and stops on deinit.
final class NWPathMonitorReachability: NetworkReachabilityMonitoring {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.yallago.reachability")
    private let subject: CurrentValueSubject<Bool, Never>

    /// Guards `isConnected` since `NWPathMonitor`'s callback fires on `queue`,
    /// while this can be read from any thread (the networking layer, the UI).
    private let lock = NSLock()
    private var _isConnected: Bool

    var isConnected: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isConnected
    }

    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    init() {
        let initialState = true // optimistic default until the first callback fires
        _isConnected = initialState
        subject = CurrentValueSubject(initialState)

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            self.lock.lock()
            self._isConnected = connected
            self.lock.unlock()
            self.subject.send(connected)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
