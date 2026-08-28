//
//  FavoritePlaceError.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Typed favourite-place failures shared by every repository implementation
/// (mock today, real API later) so callers never branch on error strings.
enum FavoritePlaceError: Error, Equatable {
    /// The favourites could not be loaded.
    case loadFailed
    /// Adding a favourite failed.
    case addFailed
    /// Updating a favourite failed.
    case updateFailed
    /// Removing a favourite failed.
    case removeFailed
    /// A favourite with this label already exists (backend enforces a
    /// unique label per user).
    case duplicateLabel
    /// The session token is missing, expired, or was rejected by the backend.
    case sessionExpired
    /// Reserved for the future networking layer.
    case networkUnavailable
    /// Any unclassified failure.
    case unknown
}
