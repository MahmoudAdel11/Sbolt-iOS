
//
//  FavoritePlaceDTO.swift
//  Yalla Go
//

import Foundation

/// Data Transfer Objects for the favourite places endpoints.
/// Fill in concrete fields once the API contract is finalised.
enum FavoritePlaceDTO {

    /// Response body for one item in GET /favorites.
    struct FavoritePlaceResponse: Decodable {
        let id: String
        let title: String
        let address: String
        let icon: String
        let latitude: Double
        let longitude: Double
        let createdAt: Date

        func toDomain() -> FavoritePlace {
            FavoritePlace(
                id: id,
                title: title,
                address: address,
                coordinate: Coordinate(latitude: latitude, longitude: longitude),
                icon: icon,
                createdAt: createdAt
            )
        }
    }
}
