//
//  UpdateFavoritePlaceUseCase.swift
//  Yalla Go
//

import Foundation

/// Updates an existing favourite place and returns the updated place.
struct UpdateFavoritePlaceUseCase {
    private let repository: FavoritePlaceRepository

    init(repository: FavoritePlaceRepository) {
        self.repository = repository
    }

    func execute(id: String, _ place: FavoritePlace) async throws -> FavoritePlace {
        try await repository.updateFavoritePlace(id: id, place)
    }
}
