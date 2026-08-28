//
//  ConnectivityStore.swift
//  Yalla Go
//

import Foundation
import Combine

/// App-wide connectivity state for UI observers (the offline banner).
/// Wraps a `NetworkReachabilityMonitoring` instance so views never touch
/// `NWPathMonitor`/`Network.framework` directly.
@MainActor
final class ConnectivityStore: ObservableObject {

    @Published private(set) var isConnected: Bool

    private let monitor: any NetworkReachabilityMonitoring
    private var cancellable: AnyCancellable?

    init(monitor: any NetworkReachabilityMonitoring = NWPathMonitorReachability()) {
        self.monitor = monitor
        self.isConnected = monitor.isConnected
        cancellable = monitor.isConnectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
            }
    }
}
