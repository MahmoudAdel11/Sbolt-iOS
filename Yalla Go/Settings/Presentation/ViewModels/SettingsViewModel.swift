//
//  SettingsViewModel.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation
import Combine

/// Drives the Settings screen: loads/saves settings, handles toggles, and
/// performs logout via the existing use case. Main-actor isolated for SwiftUI.
///
/// Depends on `SettingsRepository` directly (rather than a dedicated use case)
/// because the load/save operations carry no business logic — a forwarding use
/// case would add no value.
@MainActor
final class SettingsViewModel: ObservableObject {

    @Published private(set) var settings: AppSettings = .default
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didLogout = false

    private let settingsRepository: SettingsRepository
    private let logoutUseCase: LogoutUseCase
    private let errorPresenter: SettingsErrorPresenter
    /// Exposed read-only so callers/tests can await the in-flight operation.
    private(set) var activeTask: Task<Void, Never>?

    init(settingsRepository: SettingsRepository,
         logoutUseCase: LogoutUseCase,
         errorPresenter: SettingsErrorPresenter = SettingsErrorPresenter()) {
        self.settingsRepository = settingsRepository
        self.logoutUseCase = logoutUseCase
        self.errorPresenter = errorPresenter
    }

    deinit {
        activeTask?.cancel()
    }

    /// Loads settings. Ignored while another operation is in flight.
    func loadSettings() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        activeTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }
            do {
                let settings = try await self.settingsRepository.loadSettings()
                guard !Task.isCancelled else { return }
                self.settings = settings
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = self.errorPresenter.message(for: error)
            }
        }
    }

    func setDarkMode(_ isOn: Bool) {
        persist { $0.isDarkModeEnabled = isOn }
    }

    func setPushNotifications(_ isOn: Bool) {
        persist { $0.isPushNotificationsEnabled = isOn }
    }

    /// Signs the user out via the existing use case, updating the mock auth
    /// state. Navigation is intentionally left for a later task.
    func logout() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        didLogout = false
        activeTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }
            do {
                try await self.logoutUseCase.execute()
                guard !Task.isCancelled else { return }
                self.didLogout = true
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = self.errorPresenter.message(for: error)
            }
        }
    }

    func cancel() {
        activeTask?.cancel()
    }

    /// Clears the current error after it has been shown to the user.
    func clearError() {
        errorMessage = nil
    }

    /// Acknowledges the logout confirmation after it has been shown.
    func acknowledgeLogout() {
        didLogout = false
    }

    /// Applies a change optimistically, then persists it. Reverts on failure so
    /// the UI never shows a value the backend rejected.
    private func persist(_ mutate: (inout AppSettings) -> Void) {
        guard !isLoading else { return }

        let previous = settings
        var updated = settings
        mutate(&updated)
        guard updated != previous else { return }

        settings = updated // immediate, optimistic UI update
        isLoading = true
        errorMessage = nil

        activeTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }
            do {
                let saved = try await self.settingsRepository.saveSettings(updated)
                guard !Task.isCancelled else { return }
                self.settings = saved
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled else { return }
                self.settings = previous // revert optimistic change
                self.errorMessage = self.errorPresenter.message(for: error)
            }
        }
    }
}
