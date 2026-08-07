
//
//  FavoritePlaceDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the /favorite-places endpoints. Backend has no
/// icon/category field — it is a purely client-side computed property on
/// `FavoritePlace`, never part of the wire format.
enum FavoritePlaceDTO {

    /// Response body for POST/GET/PATCH /favorite-places.
    struct FavoritePlaceResponse: Decodable {
        let id: String
        let label: String
        let address: String
        let latitude: Double
        let longitude: Double
        let createdAt: Date

        func toDomain() -> FavoritePlace {
            FavoritePlace(
                id: id,
                title: label,
                address: address,
                coordinate: Coordinate(latitude: latitude, longitude: longitude),
                createdAt: createdAt
            )
        }
    }

    /// Request body for POST /favorite-places.
    struct FavoritePlaceCreateRequest: Encodable {
        let label: String
        let address: String
        let latitude: Double
        let longitude: Double

        init(_ place: FavoritePlace) {
            self.label = place.title
            self.address = place.address
            self.latitude = place.coordinate.latitude
            self.longitude = place.coordinate.longitude
        }
    }

    /// Request body for PATCH /favorite-places/{id}. All fields optional —
    /// this always sends the full set (never a partial subset) since the
    /// domain model doesn't track which fields actually changed.
    struct FavoritePlaceUpdateRequest: Encodable {
        let label: String?
        let address: String?
        let latitude: Double?
        let longitude: Double?

        init(_ place: FavoritePlace) {
            self.label = place.title
            self.address = place.address
            self.latitude = place.coordinate.latitude
            self.longitude = place.coordinate.longitude
        }
    }
}
