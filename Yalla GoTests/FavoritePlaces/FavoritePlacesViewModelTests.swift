//
//  FavoritePlacesViewModelTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

@MainActor
struct FavoritePlacesViewModelTests {

    private func makeSUT(places: [FavoritePlace] = MockFavoritePlaceRepository.sampleFavorites(),
                         behavior: MockFavoritePlaceRepository.Behavior = .success) -> FavoritePlacesViewModel {
        let repository = MockFavoritePlaceRepository(places: places, behavior: behavior, artificialDelay: 0)
        return FavoritePlacesViewModel(
            getFavoritePlacesUseCase: GetFavoritePlacesUseCase(repository: repository),
            addFavoritePlaceUseCase: AddFavoritePlaceUseCase(repository: repository),
            removeFavoritePlaceUseCase: RemoveFavoritePlaceUseCase(repository: repository))
    }

    private func makePlace(id: String = "fav-new") -> FavoritePlace {
        FavoritePlace(id: id,
                      title: "University",
                      address: "GUC, New Cairo",
                      coordinate: Coordinate(latitude: 29.9866, longitude: 31.4426),
                      icon: "graduationcap.fill",
                      createdAt: Date(timeIntervalSince1970: 1_719_300_000))
    }

    @Test func startsInIdleState() {
        let sut = makeSUT()
        #expect(sut.favoritePlaces.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
        #expect(sut.actionSucceeded == false)
    }

    @Test func loadSuccessPublishesFavorites() async {
        let sut = makeSUT()

        sut.loadFavorites()
        await sut.activeTask?.value

        #expect(sut.favoritePlaces.count == 3)
        #expect(sut.errorMessage == nil)
        #expect(sut.isEmpty == false)
    }

    @Test func loadSuccessWithNoFavoritesIsEmptyState() async {
        let sut = makeSUT(places: [])

        sut.loadFavorites()
        await sut.activeTask?.value

        #expect(sut.favoritePlaces.isEmpty)
        #expect(sut.isEmpty == true)
    }

    @Test func loadFailurePublishesError() async {
        let sut = makeSUT(behavior: .failure)

        sut.loadFavorites()
        await sut.activeTask?.value

        #expect(sut.favoritePlaces.isEmpty)
        #expect(sut.errorMessage == "We couldn't load your favourite places. Please try again.")
        #expect(sut.isEmpty == false)
    }

    @Test func setsLoadingWhileRequestIsInFlight() async {
        let sut = makeSUT()

        sut.loadFavorites()
        #expect(sut.isLoading == true) // set synchronously before the task runs

        await sut.activeTask?.value
        #expect(sut.isLoading == false)
    }

    @Test func addSuccessUpdatesListAndSignalsSuccess() async {
        let sut = makeSUT()

        sut.add(makePlace())
        await sut.activeTask?.value

        #expect(sut.favoritePlaces.contains { $0.id == "fav-new" })
        #expect(sut.actionSucceeded)
        #expect(sut.errorMessage == nil)
    }

    @Test func removeSuccessUpdatesList() async {
        let sut = makeSUT()

        sut.remove(id: "fav-home")
        await sut.activeTask?.value

        #expect(!sut.favoritePlaces.contains { $0.id == "fav-home" })
        #expect(sut.actionSucceeded)
    }

    @Test func addFailurePublishesError() async {
        let sut = makeSUT(behavior: .failure)

        sut.add(makePlace())
        await sut.activeTask?.value

        #expect(sut.actionSucceeded == false)
        #expect(sut.errorMessage == "We couldn't save this place. Please try again.")
    }
}
