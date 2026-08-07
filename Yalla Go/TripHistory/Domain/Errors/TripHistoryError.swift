//
//  TripHistoryError.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Typed trip-history failures shared by every repository implementation
/// (mock today, real API later) so callers never branch on error strings.
enum TripHistoryError: Error, Equatable {
    /// The history could not be loaded.
    case historyUnavailable
    /// A refresh of the history failed.
    case refreshFailed
    /// The session token is missing, expired, or was rejected by the backend.
    case sessionExpired
    /// Reserved for the future networking layer.
    case networkUnavailable
    /// Any unclassified failure.
    case unknown
}
