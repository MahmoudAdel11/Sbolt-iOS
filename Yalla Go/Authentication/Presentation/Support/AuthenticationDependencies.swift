//
//  AuthenticationDependencies.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Composition root for the authentication feature. Wires the mock repository
/// into use cases and vends view models, so views never construct use cases
/// or touch the repository directly. Swap the injected repository here to move
/// off the mock later.
@MainActor
struct AuthenticationDependencies {

    private let repository: AuthenticationRepository

    init(repository: AuthenticationRepository = MockAuthenticationRepository()) {
        self.repository = repository
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(loginUseCase: LoginUseCase(repository: repository))
    }

    func makeRegisterViewModel() -> RegisterViewModel {
        RegisterViewModel(registerUseCase: RegisterUseCase(repository: repository))
    }
}
