//
//  AuthenticationError.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Typed authentication failures shared across every repository implementation
/// (mock today, real API later) so callers never branch on error strings.
enum AuthenticationError: Error, Equatable {
    /// Email/password combination was rejected by the backend.
    case invalidCredentials
    /// Registration attempted with an email that already has an account.
    case emailAlreadyExists
    /// No account exists for the requested user.
    case userNotFound
    /// Client-side validation failed before reaching the backend.
    case invalidInput
    /// Reserved for the future networking layer.
    case networkUnavailable
    /// Any unclassified failure.
    case unknown
}
