//
//  GetFavoritePlacesUseCase.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Loads the user's saved favourite places.
struct GetFavoritePlacesUseCase {
    private let repository: FavoritePlaceRepository

    init(repository: FavoritePlaceRepository) {
        self.repository = repository
    }

    func execute() async throws -> [FavoritePlace] {
        try await repository.getFavoritePlaces()
    }
}
