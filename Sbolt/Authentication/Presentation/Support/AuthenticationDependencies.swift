//
//  AuthenticationDependencies.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Composition root for the authentication feature.
/// Resolves the active repository from `AppEnvironment.current` by default,
/// so switching environment (mock ↔ remote) requires no changes here or in views.
@MainActor
struct AuthenticationDependencies {

    private let repository: any AuthenticationRepository

    init(repository: (any AuthenticationRepository)? = nil) {
        self.repository = repository
            ?? AppEnvironment.current.repositoryFactory.makeAuthenticationRepository()
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(loginUseCase: LoginUseCase(repository: repository))
    }

    func makeRegisterViewModel() -> RegisterViewModel {
        RegisterViewModel(registerUseCase: RegisterUseCase(repository: repository))
    }
}
