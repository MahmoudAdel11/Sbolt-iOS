//
//  Trip.swift
//  Yalla Go
//

import Foundation

/// A ride in any lifecycle state, as returned by the backend. Mirrors
/// `RideResponse` field-for-field — the backend has no fare, distance,
/// duration, or location-name fields, so this model does not invent any.
/// Location display formatting (if any) belongs in the Presentation layer.
struct Trip: Identifiable, Equatable {
    let id: String
    let riderID: String
    let driverID: String?
    let status: TripStatus
    let pickupCoordinate: Coordinate
    let destinationCoordinate: Coordinate
    let requestedAt: Date
    let acceptedAt: Date?
    let completedAt: Date?
    let cancelledAt: Date?
    /// Rider-facing driver summary, embedded on the backend's `RideResponse`
    /// once a driver is assigned. `nil` until then (or if it somehow didn't
    /// decode) — defaulted so every existing call site is unaffected.
    var driver: Driver? = nil
}
