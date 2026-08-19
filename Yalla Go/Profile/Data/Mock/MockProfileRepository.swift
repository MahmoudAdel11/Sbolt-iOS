//
//  MockProfileRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// In-memory `ProfileRepository` that simulates a backend while the app has
/// none. An `actor` guarantees safe access to the mutable stored profile.
///
/// Deterministic by design: `behavior` decides whether calls succeed or throw,
/// so the same instance can drive the app and unit tests.
actor MockProfileRepository: ProfileRepository {

    enum Behavior {
        case success
        case failure
    }

    private var storedProfile: User
    private let behavior: Behavior
    private let artificialDelay: TimeInterval

    init(profile: User = MockProfileRepository.makeSampleProfile(),
         behavior: Behavior = .success,
         artificialDelay: TimeInterval = 0.5) {
        self.storedProfile = profile
        self.behavior = behavior
        self.artificialDelay = artificialDelay
    }

    func getProfile() async throws -> User {
        await simulateNetworkDelay()
        guard behavior == .success else { throw ProfileError.profileUnavailable }
        return storedProfile
    }

    func updateProfile(_ update: ProfileUpdate) async throws -> User {
        await simulateNetworkDelay()
        guard behavior == .success else { throw ProfileError.updateFailed }
        storedProfile = User(id: storedProfile.id,
                             username: update.username,
                             email: storedProfile.email,
                             phoneNumber: update.phoneNumber,
                             profileImageURL: update.profileImageURL,
                             createdAt: storedProfile.createdAt,
                             driverProfile: storedProfile.driverProfile)
        return storedProfile
    }

    // MARK: - Helpers

    private func simulateNetworkDelay() async {
        guard artificialDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(artificialDelay * 1_000_000_000))
    }

    static func makeSampleProfile() -> User {
        User(id: "mock-user-id",
             username: "Test User",
             email: "test@yallago.com",
             phoneNumber: "+201000000000",
             profileImageURL: nil,
             createdAt: Date(timeIntervalSince1970: 0),
             driverProfile: nil)
    }
}
