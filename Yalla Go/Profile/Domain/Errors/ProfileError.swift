//
//  ProfileError.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Typed profile failures shared by every repository implementation
/// (mock today, real API later) so callers never branch on error strings.
enum ProfileError: Error, Equatable {
    /// The profile could not be loaded.
    case profileUnavailable
    /// The profile update was rejected or could not be saved.
    case updateFailed
    /// Reserved for the future networking layer.
    case networkUnavailable
    /// Any unclassified failure.
    case unknown
}
