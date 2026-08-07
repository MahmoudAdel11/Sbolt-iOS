//
//  Driver.swift
//  Yalla Go
//

import Foundation

/// The driver assigned to a ride. The backend only ever exposes a bare
/// `driver_id` — no name, rating, vehicle, or plate data exists server-side
/// (confirmed: a driver is just a `User` with `role == "driver"`, nothing more).
/// All rich fields are therefore optional and `nil` when populated from the
/// remote repository; the UI must degrade gracefully rather than assume they
/// exist. Richer driver profiles are a deferred backend feature.
struct Driver: Identifiable, Equatable {
    let id: String
    var name: String?
    var rating: Double?
    var vehicleName: String?
    var vehicleColor: String?
    var plateNumber: String?
    /// SF Symbol name used as the profile image placeholder.
    var profileImage: String?
    /// Estimated arrival to the pickup point, in minutes.
    var estimatedArrivalMinutes: Int?
}
