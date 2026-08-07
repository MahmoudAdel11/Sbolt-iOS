//
//  TripFlowTimings.swift
//  Yalla Go
//

import Foundation

/// View-model-owned display timing for phases that have no backend wait: how
/// long the `cancelled`/`completed` terminal state lingers before the flow
/// resets to idle. Configurable and set to zero in tests for determinism.
struct TripFlowTimings {
    var resetAfterTerminal: TimeInterval = 2

    static let immediate = TripFlowTimings(resetAfterTerminal: 0)
}
