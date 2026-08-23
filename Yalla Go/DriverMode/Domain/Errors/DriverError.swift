//
//  DriverError.swift
//  Yalla Go
//

import Foundation

/// Typed driver-mode failures shared by every repository implementation
/// (mock today, real API later) so callers never branch on error strings.
enum DriverError: Error, Equatable {
    /// The account has no driver profile, or is offline where the backend
    /// requires it to be online (e.g. `GET /rides/available`).
    case notAuthorizedAsDriver
    /// The ride does not exist.
    case rideNotFound
    /// `POST /rides/{id}/accept` lost the race — another driver got there first.
    case rideNoLongerAvailable
    /// `POST /rides/{id}/accept` or `/complete` 409'd because the rider
    /// cancelled the ride — distinct from `.rideNoLongerAvailable` (backend
    /// `error_code: "ride_cancelled"` vs the generic `"conflict"`) so the UI
    /// doesn't misattribute the rider's cancellation to another driver.
    case rideCancelledByRider
    /// `POST /rides/{id}/complete` was called from a non-completable status.
    case rideNotCompletable
    /// The session token is missing, expired, or was rejected by the backend.
    case sessionExpired
    /// No internet connection or the request timed out.
    case networkUnavailable
    /// Any unclassified failure.
    case unknown
}
