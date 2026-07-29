//
//  Trip.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// A finished ride as shown in Trip History. Reuses the existing `RideType`
/// rather than duplicating a ride-tier enum. Contains only what the history
/// feature needs — no speculative backend fields.
struct Trip: Identifiable, Equatable {
    let id: String
    let pickupLocationName: String
    let destinationLocationName: String
    let pickupCoordinate: TripCoordinate
    let destinationCoordinate: TripCoordinate
    let price: Double
    let tripType: RideType
    /// Travelled distance in meters.
    let distance: Double
    /// Trip duration in seconds.
    let duration: TimeInterval
    let completedAt: Date
    let status: TripStatus
}
