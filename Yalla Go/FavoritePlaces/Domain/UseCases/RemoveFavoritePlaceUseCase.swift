//
//  RemoveFavoritePlaceUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Removes a place from the user's favourites and returns the updated list.
struct RemoveFavoritePlaceUseCase {
    private let repository: FavoritePlaceRepository

    init(repository: FavoritePlaceRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws -> [FavoritePlace] {
        try await repository.removeFavoritePlace(id: id)
    }
}
