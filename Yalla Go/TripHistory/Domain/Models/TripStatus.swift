//
//  TripStatus.swift
//  Yalla Go
//

import Foundation

/// A ride's lifecycle state, mirroring the backend's `RideStatus` enum
/// (`requested`, `accepted`, `ongoing`, `completed`, `cancelled`) exactly —
/// raw values match the wire strings so DTOs decode without extra mapping.
enum TripStatus: String, Equatable {
    case requested
    case accepted
    case ongoing
    case completed
    case cancelled

    /// Whether this status can no longer change.
    var isTerminal: Bool {
        self == .completed || self == .cancelled
    }

    var displayName: String {
        switch self {
        case .requested: return "Requested"
        case .accepted: return "Accepted"
        case .ongoing: return "Ongoing"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}
