//
//  TripBookingErrorPresenter.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Converts domain errors into user-facing messages in one place, so the view
/// model never leaks repository details or duplicates copy.
struct TripBookingErrorPresenter {

    func message(for error: Error) -> String {
        switch error {
        case TripBookingError.noDriverFound:
            return "No drivers available right now. Please try again."
        case TripBookingError.networkUnavailable:
            return "No internet connection. Please try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
