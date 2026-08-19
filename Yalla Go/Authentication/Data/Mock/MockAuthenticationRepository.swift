//
//  MockAuthenticationRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// In-memory `AuthenticationRepository` that simulates a backend while the app
/// has none. An `actor` guarantees safe access to the mutable session state.
///
/// Deterministic by design so it can drive both the running app and unit tests:
/// - Valid login: `validEmail` / `validPassword`.
/// - Any other credentials throw `.invalidCredentials`.
/// - Registering an already-known email throws `.emailAlreadyExists`.
actor MockAuthenticationRepository: AuthenticationRepository {

    // Seeded "server" credentials that authenticate successfully.
    private let validEmail: String
    private let validPassword: String

    // Emails already registered on the simulated backend.
    private var registeredEmails: Set<String>

    // Current session.
    private var signedInUser: User?

    // Simulated network latency in seconds; set to 0 in tests for determinism.
    private let artificialDelay: TimeInterval

    init(validEmail: String = "test@yallago.com",
         validPassword: String = "password123",
         registeredEmails: Set<String> = ["test@yallago.com"],
         artificialDelay: TimeInterval = 0.5) {
        self.validEmail = validEmail
        self.validPassword = validPassword
        self.registeredEmails = registeredEmails
        self.artificialDelay = artificialDelay
    }

    func login(email: String, password: String) async throws -> User {
        await simulateNetworkDelay()
        guard email == validEmail, password == validPassword else {
            throw AuthenticationError.invalidCredentials
        }
        let user = Self.makeUser(username: "Test User",
                                 email: email,
                                 phoneNumber: "+201000000000")
        signedInUser = user
        return user
    }

    func register(_ details: RegistrationDetails) async throws -> User {
        await simulateNetworkDelay()
        guard !registeredEmails.contains(details.email) else {
            throw AuthenticationError.emailAlreadyExists
        }
        registeredEmails.insert(details.email)
        let user = Self.makeUser(username: details.username,
                                 email: details.email,
                                 phoneNumber: details.phoneNumber,
                                 driverProfile: details.registerAsDriver ? DriverProfile(isOnline: false) : nil)
        signedInUser = user
        return user
    }

    func logout() async throws {
        await simulateNetworkDelay()
        signedInUser = nil
    }

    func currentUser() async -> User? {
        signedInUser
    }

    func isAuthenticated() async -> Bool {
        signedInUser != nil
    }

    // MARK: - Helpers

    private func simulateNetworkDelay() async {
        guard artificialDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(artificialDelay * 1_000_000_000))
    }

    private static func makeUser(username: String,
                                 email: String,
                                 phoneNumber: String,
                                 driverProfile: DriverProfile? = nil) -> User {
        User(id: UUID().uuidString,
             username: username,
             email: email,
             phoneNumber: phoneNumber,
             profileImageURL: nil,
             createdAt: Date(),
             driverProfile: driverProfile)
    }
}
