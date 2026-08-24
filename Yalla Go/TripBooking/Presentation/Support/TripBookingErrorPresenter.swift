//
//  TripBookingErrorPresenter.swift
//  Yalla Go
//

import Foundation

/// Converts domain errors into user-facing messages in one place, so the view
/// model never leaks repository details or duplicates copy.
struct TripBookingErrorPresenter {

    func message(for error: Error) -> String {
        switch error {
        case let rideError as RideError:
            return message(for: rideError)
        default:
            return "Something went wrong. Please try again."
        }
    }

    private func message(for error: RideError) -> String {
        switch error {
        case .activeRideAlreadyExists: return "You already have an active ride."
        case .rideNotFound:            return "This ride could not be found."
        case .notPartOfRide:           return "You don't have access to this ride."
        case .cancellationFailed:      return "This ride can no longer be cancelled."
        case .sessionExpired:          return "Your session has expired. Please log in again."
        case .networkUnavailable:      return "No internet connection. Please try again."
        case .ratingFailed:            return "Couldn't submit your rating. Please try again."
        case .unknown:                 return "Something went wrong. Please try again."
        }
    }
}
