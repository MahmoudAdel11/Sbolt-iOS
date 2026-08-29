//
//  AuthInputValidator.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Presentation-layer validation failures. Each case carries its own
/// UI-facing message so error text isn't duplicated across view models.
enum AuthValidationError: Error, Equatable {
    case usernameRequired
    case emailRequired
    case invalidEmail
    case phoneNumberRequired
    case passwordRequired
    case passwordTooShort
    case passwordsDoNotMatch

    var message: String {
        switch self {
        case .usernameRequired: return "Please enter your username."
        case .emailRequired: return "Please enter your email."
        case .invalidEmail: return "Please enter a valid email address."
        case .phoneNumberRequired: return "Please enter your phone number."
        case .passwordRequired: return "Please enter your password."
        case .passwordTooShort:
            return "Password must be at least \(AuthInputValidator.minimumPasswordLength) characters."
        case .passwordsDoNotMatch: return "Passwords do not match."
        }
    }
}

/// Stateless input validation shared by the authentication view models.
struct AuthInputValidator {

    /// Must match the backend's `UserRegisterRequest.password` Pydantic
    /// field (`Field(min_length=8)`, `app/api/v1/schemas/user.py`) — this
    /// was previously 6, silently out of sync with the server's actual
    /// requirement of 8. A 6-7 character password passed client-side
    /// validation, then failed server-side with a 422 that the client
    /// mapped to a generic "Please check your details and try again."
    /// message, giving no indication of what was actually wrong.
    static let minimumPasswordLength = 8

    func validateLogin(email: String, password: String) throws {
        try validateEmail(email)
        try validatePassword(password)
    }

    func validateRegistration(username: String,
                              email: String,
                              phoneNumber: String,
                              password: String,
                              confirmPassword: String) throws {
        guard !username.isBlank else { throw AuthValidationError.usernameRequired }
        try validateEmail(email)
        guard !phoneNumber.isBlank else { throw AuthValidationError.phoneNumberRequired }
        try validatePassword(password)
        guard password == confirmPassword else { throw AuthValidationError.passwordsDoNotMatch }
    }

    // MARK: - Field rules

    private func validateEmail(_ email: String) throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AuthValidationError.emailRequired }
        guard isValidEmail(trimmed) else { throw AuthValidationError.invalidEmail }
    }

    private func validatePassword(_ password: String) throws {
        guard !password.isEmpty else { throw AuthValidationError.passwordRequired }
        guard password.count >= Self.minimumPasswordLength else {
            throw AuthValidationError.passwordTooShort
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

private extension String {
    /// `true` when the string is empty or only whitespace.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
