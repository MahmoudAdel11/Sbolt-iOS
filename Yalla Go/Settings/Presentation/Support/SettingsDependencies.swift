//
//  SettingsDependencies.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Composition root for the settings feature. Wires the mock settings repository
/// and reuses the existing authentication logout use case, so the view never
/// builds dependencies itself.
struct SettingsDependencies {

    private let settingsRepository: SettingsRepository
    private let authenticationRepository: AuthenticationRepository

    init(settingsRepository: SettingsRepository = MockSettingsRepository(),
         authenticationRepository: AuthenticationRepository = MockAuthenticationRepository()) {
        self.settingsRepository = settingsRepository
        self.authenticationRepository = authenticationRepository
    }

    @MainActor
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(settingsRepository: settingsRepository,
                          logoutUseCase: LogoutUseCase(repository: authenticationRepository))
    }
}
