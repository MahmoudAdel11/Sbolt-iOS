//
//  Driver.swift
//  Yalla Go
//

import Foundation

/// The driver assigned to a ride. The backend now embeds a rider-safe
/// summary (name, vehicle, average rating) directly on `RideResponse` once a
/// driver accepts — populated via `RideDTO.RideDriverSummary.toDomain(id:)`.
/// Fields stay optional because the embedded summary is itself optional
/// (absent while `status == requested`, or if it somehow didn't decode) and
/// two fields (`profileImage`, `estimatedArrivalMinutes`) have no backend
/// equivalent at all — the UI must still degrade gracefully.
struct Driver: Identifiable, Equatable {
    let id: String
    var name: String?
    var rating: Double?
    var ratingCount: Int?
    var vehicleName: String?
    var vehicleColor: String?
    var plateNumber: String?
    /// SF Symbol name used as the profile image placeholder.
    var profileImage: String?
    /// Estimated arrival to the pickup point, in minutes.
    var estimatedArrivalMinutes: Int?
}
