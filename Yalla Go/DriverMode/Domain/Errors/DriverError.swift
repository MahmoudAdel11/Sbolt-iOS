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
    /// `POST /rides/{id}/complete` was called from a non-completable status.
    case rideNotCompletable
    /// The session token is missing, expired, or was rejected by the backend.
    case sessionExpired
    /// No internet connection or the request timed out.
    case networkUnavailable
    /// Any unclassified failure.
    case unknown
}
