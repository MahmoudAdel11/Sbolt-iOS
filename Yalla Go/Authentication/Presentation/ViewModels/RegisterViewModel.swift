//
//  RegisterViewModel.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation
import Combine

/// Drives the (future) registration screen: owns form state, validates input,
/// and coordinates `RegisterUseCase`. Main-actor isolated for SwiftUI.
@MainActor
final class RegisterViewModel: ObservableObject {

    // Inputs bound by the view.
    @Published var username = ""
    @Published var email = ""
    @Published var phoneNumber = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    // Outputs the view observes.
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var registrationSucceeded = false

    private let registerUseCase: RegisterUseCase
    private let validator: AuthInputValidator
    private let errorPresenter: AuthErrorPresenter
    /// Exposed read-only so callers/tests can await the in-flight attempt.
    private(set) var registerTask: Task<Void, Never>?

    init(registerUseCase: RegisterUseCase,
         validator: AuthInputValidator = AuthInputValidator(),
         errorPresenter: AuthErrorPresenter = AuthErrorPresenter()) {
        self.registerUseCase = registerUseCase
        self.validator = validator
        self.errorPresenter = errorPresenter
    }

    deinit {
        registerTask?.cancel()
    }

    /// Starts a registration attempt. Ignores taps while a request is in flight.
    func register() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        registrationSucceeded = false
        registerTask = Task { [weak self] in
            await self?.performRegistration()
        }
    }

    /// Cancels an in-flight registration (e.g. when the screen disappears).
    func cancel() {
        registerTask?.cancel()
    }

    private func performRegistration() async {
        defer { isLoading = false }

        do {
            try validator.validateRegistration(username: username,
                                               email: email,
                                               phoneNumber: phoneNumber,
                                               password: password,
                                               confirmPassword: confirmPassword)
        } catch {
            errorMessage = errorPresenter.message(for: error)
            return
        }

        let details = RegistrationDetails(username: username,
                                          email: email,
                                          phoneNumber: phoneNumber,
                                          password: password)
        do {
            _ = try await registerUseCase.execute(details)
            guard !Task.isCancelled else { return }
            registrationSucceeded = true
        } catch is CancellationError {
            // Superseded/cancelled: leave state untouched.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = errorPresenter.message(for: error)
        }
    }
}
