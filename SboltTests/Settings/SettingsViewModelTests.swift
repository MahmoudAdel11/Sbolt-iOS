//
//  SettingsViewModelTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Sbolt

@MainActor
struct SettingsViewModelTests {

    private func makeSUT(settings: AppSettings = .default,
                         behavior: MockSettingsRepository.Behavior = .success)
    -> (SettingsViewModel, MockAuthenticationRepository) {
        let settingsRepository = MockSettingsRepository(settings: settings,
                                                        behavior: behavior,
                                                        artificialDelay: 0)
        let authRepository = MockAuthenticationRepository(artificialDelay: 0)
        let sut = SettingsViewModel(settingsRepository: settingsRepository,
                                    logoutUseCase: LogoutUseCase(repository: authRepository))
        return (sut, authRepository)
    }

    @Test func startsWithDefaultSettings() {
        let (sut, _) = makeSUT()
        #expect(sut.settings == .default)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
        #expect(sut.didLogout == false)
    }

    @Test func loadSettingsSuccess() async {
        var stored = AppSettings.default
        stored.isPushNotificationsEnabled = false
        let (sut, _) = makeSUT(settings: stored)

        sut.loadSettings()
        await sut.activeTask?.value

        #expect(sut.settings.isPushNotificationsEnabled == false)
        #expect(sut.errorMessage == nil)
    }

    @Test func loadSettingsFailurePublishesError() async {
        let (sut, _) = makeSUT(behavior: .failure)

        sut.loadSettings()
        await sut.activeTask?.value

        #expect(sut.errorMessage == "We couldn't load your settings. Please try again.")
    }

    @Test func toggleNotificationsUpdatesImmediatelyAndPersists() async {
        let (sut, _) = makeSUT()
        #expect(sut.settings.isPushNotificationsEnabled == true)

        sut.setPushNotifications(false)
        #expect(sut.settings.isPushNotificationsEnabled == false) // optimistic, synchronous
        await sut.activeTask?.value

        #expect(sut.settings.isPushNotificationsEnabled == false)
        #expect(sut.errorMessage == nil)
    }

    @Test func toggleFailureRevertsAndPublishesError() async {
        let (sut, _) = makeSUT(behavior: .failure)

        sut.setPushNotifications(false)
        #expect(sut.settings.isPushNotificationsEnabled == false) // optimistic
        await sut.activeTask?.value

        #expect(sut.settings.isPushNotificationsEnabled == true) // reverted
        #expect(sut.errorMessage == "We couldn't save your settings. Please try again.")
    }

    @Test func setsLoadingWhileRequestIsInFlight() async {
        let (sut, _) = makeSUT()

        sut.loadSettings()
        #expect(sut.isLoading == true) // set synchronously before the task runs

        await sut.activeTask?.value
        #expect(sut.isLoading == false)
    }

    @Test func logoutSucceedsAndSignsOutMockRepository() async {
        let (sut, authRepository) = makeSUT()
        _ = try? await authRepository.login(email: "test@yallago.com", password: "password123")
        #expect(await authRepository.isAuthenticated())

        sut.logout()
        await sut.activeTask?.value

        #expect(sut.didLogout == true)
        #expect(await authRepository.isAuthenticated() == false)
    }
}
