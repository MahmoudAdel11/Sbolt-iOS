//
//  AddFavoritePlaceUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Adds a place to the user's favourites and returns the updated list.
struct AddFavoritePlaceUseCase {
    private let repository: FavoritePlaceRepository

    init(repository: FavoritePlaceRepository) {
        self.repository = repository
    }

    func execute(_ place: FavoritePlace) async throws -> [FavoritePlace] {
        try await repository.addFavoritePlace(place)
    }
}
