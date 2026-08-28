//
//  RideError.swift
//  Yalla Go
//

import Foundation

/// Typed ride-booking failures shared by every repository implementation
/// (mock today, real API later) so callers never branch on error strings.
enum RideError: Error, Equatable {
    /// The rider already has an active (non-terminal) ride — the backend
    /// allows only one at a time.
    case activeRideAlreadyExists
    /// The requested ride does not exist.
    case rideNotFound
    /// The current user is neither the rider nor the driver on this ride.
    case notPartOfRide
    /// The ride could not be cancelled from its current status.
    case cancellationFailed
    /// The session token is missing, expired, or was rejected by the backend.
    case sessionExpired
    /// No internet connection or the request timed out.
    case networkUnavailable
    /// `POST /rides/{id}/rating` failed — covers every cause (already rated,
    /// network, etc.) uniformly since the UI doesn't act differently on any
    /// of them: submitting a rating is optional and never blocks the flow.
    case ratingFailed
    /// Any unclassified failure.
    case unknown
}
