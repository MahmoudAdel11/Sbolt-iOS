//
//  FavoritePlacesDependencies.swift
//  Yalla Go
//

import Foundation

/// Composition root for the favourite-places feature. Wires the environment's
/// repository into the use cases and vends the view model, so views never
/// build use cases or touch the repository directly.
struct FavoritePlacesDependencies {

    private let repository: any FavoritePlaceRepository

    init(repository: (any FavoritePlaceRepository)? = nil) {
        self.repository = repository ?? AppEnvironment.current.repositoryFactory.makeFavoritePlaceRepository()
    }

    @MainActor
    func makeFavoritePlacesViewModel() -> FavoritePlacesViewModel {
        FavoritePlacesViewModel(
            getFavoritePlacesUseCase: GetFavoritePlacesUseCase(repository: repository),
            addFavoritePlaceUseCase: AddFavoritePlaceUseCase(repository: repository),
            updateFavoritePlaceUseCase: UpdateFavoritePlaceUseCase(repository: repository),
            removeFavoritePlaceUseCase: RemoveFavoritePlaceUseCase(repository: repository)
        )
    }
}
