
//
//  TripDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the trip history endpoints.
/// Fill in concrete fields once the API contract is finalised.
enum TripDTO {

    /// Response body for one item in GET /trips.
    struct TripResponse: Decodable {
        let id: String
        let status: String
        let rideType: String
        let originTitle: String
        let destinationTitle: String
        let originLatitude: Double
        let originLongitude: Double
        let destinationLatitude: Double
        let destinationLongitude: Double
        let distanceMeters: Double
        let durationSeconds: Double
        let priceAmount: Double
        let createdAt: Date
    }
}
