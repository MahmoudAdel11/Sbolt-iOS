//
//  FavoritePlaceErrorPresenter.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Converts domain errors into user-facing messages in one place, so the view
/// model never leaks repository details or duplicates copy.
struct FavoritePlaceErrorPresenter {

    func message(for error: Error) -> String {
        switch error {
        case let placeError as FavoritePlaceError:
            return message(for: placeError)
        default:
            return "Something went wrong. Please try again."
        }
    }

    private func message(for error: FavoritePlaceError) -> String {
        switch error {
        case .loadFailed: return "We couldn't load your favourite places. Please try again."
        case .addFailed: return "We couldn't save this place. Please try again."
        case .removeFailed: return "We couldn't remove this place. Please try again."
        case .networkUnavailable: return "No internet connection. Please try again."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}
