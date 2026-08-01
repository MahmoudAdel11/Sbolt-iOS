//
//  FavoritePlaceRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Boundary between the domain and whatever stores favourite places
/// (a mock today, a real API later). Add/remove return the updated list so the
/// caller always reflects the latest server state.
protocol FavoritePlaceRepository {
    func getFavoritePlaces() async throws -> [FavoritePlace]
    func addFavoritePlace(_ place: FavoritePlace) async throws -> [FavoritePlace]
    func removeFavoritePlace(id: String) async throws -> [FavoritePlace]
}
