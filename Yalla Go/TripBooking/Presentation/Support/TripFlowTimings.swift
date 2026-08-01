//
//  TripFlowTimings.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// View-model-owned display timings for phases that have no backend wait
/// (how long to show "Driver found" and "Trip completed", and how long the
/// cancelled state lingers before returning to idle). Configurable and set to
/// zero in tests for determinism.
struct TripFlowTimings {
    var driverFoundDisplay: TimeInterval = 2
    var tripCompletedDisplay: TimeInterval = 2
    var resetAfterCancel: TimeInterval = 1

    static let immediate = TripFlowTimings(driverFoundDisplay: 0,
                                           tripCompletedDisplay: 0,
                                           resetAfterCancel: 0)
}
