//
//  TripHistoryErrorPresenter.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Converts domain errors into user-facing messages in one place, so the view
/// model never leaks repository details or duplicates copy.
struct TripHistoryErrorPresenter {

    func message(for error: Error) -> String {
        switch error {
        case let historyError as TripHistoryError:
            return message(for: historyError)
        default:
            return "Something went wrong. Please try again."
        }
    }

    private func message(for error: TripHistoryError) -> String {
        switch error {
        case .historyUnavailable: return "We couldn't load your trips. Please try again."
        case .refreshFailed: return "We couldn't refresh your trips. Please try again."
        case .networkUnavailable: return "No internet connection. Please try again."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}
