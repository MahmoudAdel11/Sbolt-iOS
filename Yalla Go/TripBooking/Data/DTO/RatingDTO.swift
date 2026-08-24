//
//  RatingDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for POST /rides/{id}/rating. Same
/// convertFromSnakeCase/convertToSnakeCase convention as RideDTO — no
/// manual CodingKeys.
enum RatingDTO {
    struct RatingRequest: Encodable {
        let score: Int
    }

    /// Mirrors the backend's full RatingResponse field-for-field, even
    /// though iOS only needs "did this succeed" today — same discipline as
    /// RideDTO.RideResponse mirroring every backend field.
    struct RatingResponse: Decodable {
        let id: String
        let rideId: String
        let riderId: String
        let driverId: String
        let score: Int
        let createdAt: Date
    }
}
