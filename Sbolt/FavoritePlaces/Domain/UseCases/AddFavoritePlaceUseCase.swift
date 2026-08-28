//
//  AddFavoritePlaceUseCase.swift
//  Yalla Go
//

import Foundation

/// Adds a place to the user's favourites and returns the created place.
struct AddFavoritePlaceUseCase {
    private let repository: FavoritePlaceRepository

    init(repository: FavoritePlaceRepository) {
        self.repository = repository
    }

    func execute(_ place: FavoritePlace) async throws -> FavoritePlace {
        try await repository.addFavoritePlace(place)
    }
}
