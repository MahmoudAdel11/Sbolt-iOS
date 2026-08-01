//
//  TripBookingError.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Typed booking failures shared by every repository implementation
/// (mock today, real API later) so callers never branch on error strings.
enum TripBookingError: Error, Equatable {
    /// No nearby driver accepted the request.
    case noDriverFound
    /// Reserved for the future networking layer.
    case networkUnavailable
    /// Any unclassified failure.
    case unknown
}
