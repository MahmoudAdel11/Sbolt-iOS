//
//  RideDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the `/rides` endpoints. Confirmed against the
/// backend's actual schemas (`RideRequestSchema`, `RideResponse`,
/// `RideHistoryResponse`) — canonical for both TripBooking (request/cancel/
/// detail) and TripHistory (history list), since both hit the same resource.
///
/// All snake_case <-> camelCase mapping is handled automatically by
/// `JSONDecoder.backend`/`JSONEncoder.backend`. No manual `CodingKeys` —
/// adding one here previously broke decoding by fighting the automatic
/// key conversion (see Sprint 3.1).
enum RideDTO {

    /// Request body for POST /rides. Lat/lng only — the backend has no
    /// address-string or ride-tier field.
    struct RideRequest: Encodable {
        let pickupLatitude: Double
        let pickupLongitude: Double
        let dropoffLatitude: Double
        let dropoffLongitude: Double
    }

    /// Response body for POST /rides, GET /rides/{id}, POST /rides/{id}/cancel.
    struct RideResponse: Decodable {
        let id: String
        let riderId: String
        let driverId: String?
        let status: String
        let pickupLatitude: Double
        let pickupLongitude: Double
        let dropoffLatitude: Double
        let dropoffLongitude: Double
        let requestedAt: Date
        let acceptedAt: Date?
        let completedAt: Date?
        let cancelledAt: Date?

        func toDomain() -> Trip {
            Trip(
                id: id,
                riderID: riderId,
                driverID: driverId,
                status: TripStatus(rawValue: status) ?? .requested,
                pickupCoordinate: Coordinate(latitude: pickupLatitude, longitude: pickupLongitude),
                destinationCoordinate: Coordinate(latitude: dropoffLatitude, longitude: dropoffLongitude),
                requestedAt: requestedAt,
                acceptedAt: acceptedAt,
                completedAt: completedAt,
                cancelledAt: cancelledAt
            )
        }
    }

    /// Response body for GET /rides/history.
    struct RideHistoryResponse: Decodable {
        let items: [RideResponse]
        let hasMore: Bool
    }
}
