//
//  FavoritePlaceRepository.swift
//  Yalla Go
//

import Foundation

/// Boundary between the domain and whatever stores favourite places
/// (a mock today, a real API later). Mutations return only the affected
/// object (or nothing, for delete) — matching what the backend actually
/// returns — so the caller updates its own in-memory list rather than the
/// repository re-fetching the full list after every mutation.
protocol FavoritePlaceRepository {
    func getFavoritePlaces() async throws -> [FavoritePlace]
    func addFavoritePlace(_ place: FavoritePlace) async throws -> FavoritePlace
    func updateFavoritePlace(id: String, _ place: FavoritePlace) async throws -> FavoritePlace
    func removeFavoritePlace(id: String) async throws
}
