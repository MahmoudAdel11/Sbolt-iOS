//
//  MockSettingsRepositoryTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Sbolt

struct MockSettingsRepositoryTests {

    @Test func loadReturnsDefaultSettingsOnSuccess() async throws {
        let sut = MockSettingsRepository(artificialDelay: 0)
        let settings = try await sut.loadSettings()
        #expect(settings == .default)
    }

    @Test func loadFails() async {
        let sut = MockSettingsRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: SettingsError.loadFailed) {
            _ = try await sut.loadSettings()
        }
    }

    @Test func saveUpdatesAndPersistsSettings() async throws {
        let sut = MockSettingsRepository(artificialDelay: 0)
        var updated = AppSettings.default
        updated.isPushNotificationsEnabled = false

        let saved = try await sut.saveSettings(updated)
        #expect(saved.isPushNotificationsEnabled == false)

        let reloaded = try await sut.loadSettings()
        #expect(reloaded.isPushNotificationsEnabled == false)
    }

    @Test func saveFails() async {
        let sut = MockSettingsRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: SettingsError.saveFailed) {
            _ = try await sut.saveSettings(.default)
        }
    }
}
