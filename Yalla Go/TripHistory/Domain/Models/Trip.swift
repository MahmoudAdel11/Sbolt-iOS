//
//  Trip.swift
//  Yalla Go
//

import Foundation

/// A ride in any lifecycle state, as returned by the backend. Mirrors
/// `RideResponse` field-for-field — the backend has no distance/duration/
/// location-name fields, so this model does not invent any. `fare` IS a real
/// backend field now (server-computed, frozen at request time), unlike the
/// old client-side-only estimate this replaced.
/// Location display formatting (if any) belongs in the Presentation layer.
struct Trip: Identifiable, Equatable {
    let id: String
    let riderID: String
    let driverID: String?
    let status: TripStatus
    let pickupCoordinate: Coordinate
    let destinationCoordinate: Coordinate
    /// No default, unlike `driver` below — every real ride always has both
    /// (the backend's `tier`/`fare` columns are NOT NULL from creation),
    /// unlike a driver assignment which is legitimately absent until accepted.
    let tier: RideType
    let fare: Double
    let requestedAt: Date
    let acceptedAt: Date?
    let completedAt: Date?
    let cancelledAt: Date?
    /// Rider-facing driver summary, embedded on the backend's `RideResponse`
    /// once a driver is assigned. `nil` until then (or if it somehow didn't
    /// decode) — defaulted so every existing call site is unaffected.
    var driver: Driver? = nil
}
