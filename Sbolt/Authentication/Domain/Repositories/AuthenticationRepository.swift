//
//  AuthenticationRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Boundary between the domain and whatever provides authentication
/// (a mock today, a real API later). Use cases depend only on this protocol,
/// so swapping the implementation requires no changes above the Data layer.
protocol AuthenticationRepository {
    /// Authenticates with email + password, returning the signed-in user.
    func login(email: String, password: String) async throws -> User

    /// Creates a new account and returns the signed-in user.
    func register(_ details: RegistrationDetails) async throws -> User

    /// Ends the current session.
    func logout() async throws

    /// The currently signed-in user, or `nil` when signed out.
    func currentUser() async -> User?

    /// Whether a user is currently signed in.
    func isAuthenticated() async -> Bool
}
