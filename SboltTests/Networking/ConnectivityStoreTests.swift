//
//  ConnectivityStoreTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
import Combine
@testable import Sbolt

/// Fake reachability monitor whose state can be flipped on demand, so
/// `ConnectivityStore` can be tested without real `NWPathMonitor` callbacks.
private final class MockReachabilityMonitor: NetworkReachabilityMonitoring {
    private let subject: CurrentValueSubject<Bool, Never>

    var isConnected: Bool { subject.value }
    var isConnectedPublisher: AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }

    init(isConnected: Bool = true) {
        subject = CurrentValueSubject(isConnected)
    }

    func setConnected(_ connected: Bool) {
        subject.send(connected)
    }
}

@MainActor
struct ConnectivityStoreTests {

    @Test func startsWithMonitorsInitialState() {
        let monitor = MockReachabilityMonitor(isConnected: false)
        let sut = ConnectivityStore(monitor: monitor)
        #expect(sut.isConnected == false)
    }

    @Test func publishesWhenConnectivityIsLost() async throws {
        let monitor = MockReachabilityMonitor(isConnected: true)
        let sut = ConnectivityStore(monitor: monitor)
        #expect(sut.isConnected == true)

        monitor.setConnected(false)
        try await Task.sleep(nanoseconds: 10_000_000) // let the Combine sink run
        #expect(sut.isConnected == false)
    }

    @Test func publishesWhenConnectivityIsRestored() async throws {
        let monitor = MockReachabilityMonitor(isConnected: false)
        let sut = ConnectivityStore(monitor: monitor)
        #expect(sut.isConnected == false)

        monitor.setConnected(true)
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(sut.isConnected == true)
    }
}
