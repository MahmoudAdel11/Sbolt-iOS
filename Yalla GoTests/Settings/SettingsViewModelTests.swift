//
//  SettingsViewModelTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

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
        stored.isDarkModeEnabled = true
        let (sut, _) = makeSUT(settings: stored)

        sut.loadSettings()
        await sut.activeTask?.value

        #expect(sut.settings.isDarkModeEnabled == true)
        #expect(sut.errorMessage == nil)
    }

    @Test func loadSettingsFailurePublishesError() async {
        let (sut, _) = makeSUT(behavior: .failure)

        sut.loadSettings()
        await sut.activeTask?.value

        #expect(sut.errorMessage == "We couldn't load your settings. Please try again.")
    }

    @Test func toggleDarkModeUpdatesImmediatelyAndPersists() async {
        let (sut, _) = makeSUT()
        #expect(sut.settings.isDarkModeEnabled == false)

        sut.setDarkMode(true)
        #expect(sut.settings.isDarkModeEnabled == true) // optimistic, synchronous
        await sut.activeTask?.value

        #expect(sut.settings.isDarkModeEnabled == true)
        #expect(sut.errorMessage == nil)
    }

    @Test func toggleNotificationsUpdatesState() async {
        let (sut, _) = makeSUT()

        sut.setPushNotifications(false)
        #expect(sut.settings.isPushNotificationsEnabled == false)
        await sut.activeTask?.value

        #expect(sut.settings.isPushNotificationsEnabled == false)
    }

    @Test func toggleFailureRevertsAndPublishesError() async {
        let (sut, _) = makeSUT(behavior: .failure)

        sut.setDarkMode(true)
        #expect(sut.settings.isDarkModeEnabled == true) // optimistic
        await sut.activeTask?.value

        #expect(sut.settings.isDarkModeEnabled == false) // reverted
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
