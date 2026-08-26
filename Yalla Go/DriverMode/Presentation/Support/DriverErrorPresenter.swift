//
//  DriverErrorPresenter.swift
//  Yalla Go
//

import Foundation

/// Converts domain errors into user-facing messages in one place, so the view
/// model never leaks repository details or duplicates copy.
struct DriverErrorPresenter {

    func message(for error: Error) -> String {
        switch error {
        case let driverError as DriverError:
            return message(for: driverError)
        default:
            return "Something went wrong. Please try again."
        }
    }

    private func message(for error: DriverError) -> String {
        switch error {
        case .notAuthorizedAsDriver:     return "You need to be online to see available rides."
        case .rideNotFound:              return "This ride could not be found."
        case .rideNoLongerAvailable:     return "This ride was just accepted by another driver."
        case .rideCancelledByRider:      return "This ride was cancelled by the rider."
        case .rideNotStartable:          return "This ride can't be started right now."
        case .rideNotCompletable:        return "This ride can't be completed right now."
        case .sessionExpired:            return "Your session has expired. Please log in again."
        case .networkUnavailable:        return "No internet connection. Please try again."
        case .unknown:                   return "Something went wrong. Please try again."
        }
    }
}
