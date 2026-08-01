//
//  SettingsErrorPresenter.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Converts domain errors into user-facing messages in one place, so the view
/// model never leaks repository details or duplicates copy. Handles both
/// settings and authentication (logout) failures.
struct SettingsErrorPresenter {

    func message(for error: Error) -> String {
        switch error {
        case let settingsError as SettingsError:
            return message(for: settingsError)
        case is AuthenticationError:
            return "We couldn't sign you out. Please try again."
        default:
            return "Something went wrong. Please try again."
        }
    }

    private func message(for error: SettingsError) -> String {
        switch error {
        case .loadFailed: return "We couldn't load your settings. Please try again."
        case .saveFailed: return "We couldn't save your settings. Please try again."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}
