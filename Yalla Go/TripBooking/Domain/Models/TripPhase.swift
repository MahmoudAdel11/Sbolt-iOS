//
//  TripPhase.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Single source of truth for the booking flow. Enum-based (not booleans) so
/// only one valid state exists at a time and associated data travels with it.
enum TripPhase: Equatable {
    case idle
    case searching
    case driverFound(Driver)
    case driverArriving(Driver)
    case tripStarted(Driver)
    case tripCompleted
    case cancelled
    case failed(message: String)

    /// The matched driver, when the current phase has one.
    var driver: Driver? {
        switch self {
        case let .driverFound(driver),
             let .driverArriving(driver),
             let .tripStarted(driver):
            return driver
        default:
            return nil
        }
    }

    /// Whether the flow is at rest and a new booking can begin.
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    /// Cancellation is only allowed while searching or while the driver is arriving.
    var isCancellable: Bool {
        switch self {
        case .searching, .driverArriving:
            return true
        default:
            return false
        }
    }
}
