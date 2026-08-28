//
//  SettingsError.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Typed settings failures shared by every repository implementation
/// (mock today, real API later) so callers never branch on error strings.
enum SettingsError: Error, Equatable {
    /// Settings could not be loaded.
    case loadFailed
    /// Settings could not be saved.
    case saveFailed
    /// Any unclassified failure.
    case unknown
}
