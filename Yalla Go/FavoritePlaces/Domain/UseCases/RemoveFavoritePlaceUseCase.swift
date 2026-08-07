//
//  RemoveFavoritePlaceUseCase.swift
//  Yalla Go
//

import Foundation

/// Removes a place from the user's favourites.
struct RemoveFavoritePlaceUseCase {
    private let repository: FavoritePlaceRepository

    init(repository: FavoritePlaceRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws {
        try await repository.removeFavoritePlace(id: id)
    }
}
