//
//  AuthErrorPresenter.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Converts domain and validation errors into user-facing messages in a single
/// place, so no view model leaks repository details or duplicates copy.
struct AuthErrorPresenter {

    func message(for error: Error) -> String {
        switch error {
        case let validation as AuthValidationError:
            return validation.message
        case let authentication as AuthenticationError:
            return message(for: authentication)
        default:
            return "Something went wrong. Please try again."
        }
    }

    private func message(for error: AuthenticationError) -> String {
        switch error {
        case .invalidCredentials: return "Incorrect email or password."
        case .emailAlreadyExists: return "An account with this email already exists."
        case .userNotFound: return "We couldn't find an account for these details."
        case .invalidInput: return "Please check your details and try again."
        case .networkUnavailable: return "No internet connection. Please try again."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}
