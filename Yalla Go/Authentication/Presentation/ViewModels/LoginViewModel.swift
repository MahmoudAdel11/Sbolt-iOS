//
//  LoginViewModel.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation
import Combine

/// Drives the (future) login screen: owns form state, validates input, and
/// coordinates `LoginUseCase`. Isolated to the main actor because it publishes
/// SwiftUI-observed state.
@MainActor
final class LoginViewModel: ObservableObject {

    // Inputs bound by the view.
    @Published var email = ""
    @Published var password = ""

    // Outputs the view observes.
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var loginSucceeded = false
    @Published private(set) var authenticatedUser: User?

    private let loginUseCase: LoginUseCase
    private let validator: AuthInputValidator
    private let errorPresenter: AuthErrorPresenter
    /// Exposed read-only so callers/tests can await the in-flight attempt.
    private(set) var loginTask: Task<Void, Never>?

    init(loginUseCase: LoginUseCase,
         validator: AuthInputValidator = AuthInputValidator(),
         errorPresenter: AuthErrorPresenter = AuthErrorPresenter()) {
        self.loginUseCase = loginUseCase
        self.validator = validator
        self.errorPresenter = errorPresenter
    }

    deinit {
        loginTask?.cancel()
    }

    /// Starts a login attempt. Ignores taps while a request is in flight.
    func login() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        loginSucceeded = false
        loginTask = Task { [weak self] in
            await self?.performLogin()
        }
    }

    /// Cancels an in-flight login (e.g. when the screen disappears).
    func cancel() {
        loginTask?.cancel()
    }

    private func performLogin() async {
        defer { isLoading = false }

        do {
            try validator.validateLogin(email: email, password: password)
        } catch {
            errorMessage = errorPresenter.message(for: error)
            return
        }

        do {
            let user = try await loginUseCase.execute(email: email, password: password)
            guard !Task.isCancelled else { return }
            authenticatedUser = user
            loginSucceeded = true
        } catch is CancellationError {
            // Superseded/cancelled: leave state untouched.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = errorPresenter.message(for: error)
        }
    }
}
