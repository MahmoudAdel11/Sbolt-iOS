//
//  ProfileRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Boundary between the domain and whatever provides the user's profile
/// (a mock today, a real API later). Reuses the existing `User` domain model
/// rather than introducing a duplicate profile type.
protocol ProfileRepository {
    /// Loads the current user's profile.
    func getProfile() async throws -> User

    /// Persists the editable profile fields and returns the updated profile.
    func updateProfile(_ update: ProfileUpdate) async throws -> User
}
