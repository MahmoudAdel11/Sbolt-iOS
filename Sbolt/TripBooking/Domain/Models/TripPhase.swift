//
//  TripPhase.swift
//  Yalla Go
//

import Foundation

/// Single source of truth for the booking flow. Enum-based (not booleans) so
/// only one valid state exists at a time and the associated ride travels
/// with it once one exists.
enum TripPhase: Equatable {
    case idle
    /// POST /rides is in flight — no ride exists yet, so nothing to cancel.
    case requesting
    /// A ride exists and is being polled; `Trip.status` drives the sub-state
    /// shown (requested/accepted/ongoing) and whether a driver is assigned.
    case active(Trip)
    case completed(Trip)
    case cancelled
    case failed(message: String)

    /// The current ride, when the phase has one.
    var trip: Trip? {
        switch self {
        case let .active(trip), let .completed(trip):
            return trip
        default:
            return nil
        }
    }

    /// Whether the flow is at rest and a new booking can begin.
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    /// Cancellation is only possible once a ride exists and hasn't reached a
    /// terminal status.
    var isCancellable: Bool {
        if case let .active(trip) = self { return !trip.status.isTerminal }
        return false
    }
}
