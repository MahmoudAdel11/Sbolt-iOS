//
//  ProfileErrorPresenter.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Converts domain errors into user-facing messages in one place, so the view
/// model never leaks repository details or duplicates copy.
struct ProfileErrorPresenter {

    func message(for error: Error) -> String {
        switch error {
        case let profileError as ProfileError:
            return message(for: profileError)
        default:
            return "Something went wrong. Please try again."
        }
    }

    private func message(for error: ProfileError) -> String {
        switch error {
        case .profileUnavailable: return "We couldn't load your profile. Please try again."
        case .updateFailed: return "We couldn't save your changes. Please try again."
        case .networkUnavailable: return "No internet connection. Please try again."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}
