//
//  MockSettingsRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// In-memory `SettingsRepository` that simulates a backend while the app has
/// none. An `actor` guarantees safe access to the mutable settings; `behavior`
/// makes success and failure scenarios deterministic for tests.
actor MockSettingsRepository: SettingsRepository {

    enum Behavior {
        case success
        case failure
    }

    private var settings: AppSettings
    private let behavior: Behavior
    private let artificialDelay: TimeInterval

    init(settings: AppSettings = .default,
         behavior: Behavior = .success,
         artificialDelay: TimeInterval = 0.5) {
        self.settings = settings
        self.behavior = behavior
        self.artificialDelay = artificialDelay
    }

    func loadSettings() async throws -> AppSettings {
        await simulateNetworkDelay()
        guard behavior == .success else { throw SettingsError.loadFailed }
        return settings
    }

    func saveSettings(_ settings: AppSettings) async throws -> AppSettings {
        await simulateNetworkDelay()
        guard behavior == .success else { throw SettingsError.saveFailed }
        self.settings = settings
        return settings
    }

    private func simulateNetworkDelay() async {
        guard artificialDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(artificialDelay * 1_000_000_000))
    }
}
