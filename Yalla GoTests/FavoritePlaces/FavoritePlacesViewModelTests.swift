//
//  FavoritePlacesViewModelTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

/// Throws a fixed error regardless of call — used to test how the ViewModel
/// reacts to a specific typed error without widening `MockFavoritePlaceRepository`.
private struct FailingFavoritePlaceRepository: FavoritePlaceRepository {
    let error: Error
    func getFavoritePlaces() async throws -> [FavoritePlace] { throw error }
    func addFavoritePlace(_ place: FavoritePlace) async throws -> FavoritePlace { throw error }
    func updateFavoritePlace(id: String, _ place: FavoritePlace) async throws -> FavoritePlace { throw error }
    func removeFavoritePlace(id: String) async throws { throw error }
}

@MainActor
struct FavoritePlacesViewModelTests {

    private func makeSUT(places: [FavoritePlace] = MockFavoritePlaceRepository.sampleFavorites(),
                         behavior: MockFavoritePlaceRepository.Behavior = .success) -> FavoritePlacesViewModel {
        let repository = MockFavoritePlaceRepository(places: places, behavior: behavior, artificialDelay: 0)
        return FavoritePlacesViewModel(
            getFavoritePlacesUseCase: GetFavoritePlacesUseCase(repository: repository),
            addFavoritePlaceUseCase: AddFavoritePlaceUseCase(repository: repository),
            updateFavoritePlaceUseCase: UpdateFavoritePlaceUseCase(repository: repository),
            removeFavoritePlaceUseCase: RemoveFavoritePlaceUseCase(repository: repository))
    }

    private func makePlace(id: String = "fav-new", title: String = "University") -> FavoritePlace {
        FavoritePlace(id: id,
                      title: title,
                      address: "GUC, New Cairo",
                      coordinate: Coordinate(latitude: 29.9866, longitude: 31.4426),
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

    @Test func addSuccessInsertsIntoLocalListWithoutRefetch() async {
        let sut = makeSUT()
        sut.loadFavorites()
        await sut.activeTask?.value
        #expect(sut.favoritePlaces.count == 3)

        sut.add(makePlace())
        await sut.activeTask?.value

        #expect(sut.favoritePlaces.count == 4)
        #expect(sut.favoritePlaces.contains { $0.id == "fav-new" })
        #expect(sut.actionSucceeded)
        #expect(sut.errorMessage == nil)
    }

    @Test func addFailurePublishesError() async {
        let sut = makeSUT(behavior: .failure)

        sut.add(makePlace())
        await sut.activeTask?.value

        #expect(sut.actionSucceeded == false)
        #expect(sut.errorMessage == "We couldn't save this place. Please try again.")
    }

    @Test func updateSuccessReplacesInLocalList() async {
        let sut = makeSUT()
        sut.loadFavorites()
        await sut.activeTask?.value

        sut.update(id: "fav-home", makePlace(id: "fav-home", title: "New Home"))
        await sut.activeTask?.value

        #expect(sut.favoritePlaces.count == 3) // replaced, not appended
        #expect(sut.favoritePlaces.first { $0.id == "fav-home" }?.title == "New Home")
        #expect(sut.actionSucceeded)
    }

    @Test func updateFailurePublishesError() async {
        let sut = makeSUT(behavior: .failure)

        sut.update(id: "fav-home", makePlace())
        await sut.activeTask?.value

        #expect(sut.actionSucceeded == false)
        #expect(sut.errorMessage == "We couldn't update this place. Please try again.")
    }

    @Test func removeSuccessRemovesFromLocalList() async {
        let sut = makeSUT()
        sut.loadFavorites()
        await sut.activeTask?.value

        sut.remove(id: "fav-home")
        await sut.activeTask?.value

        #expect(!sut.favoritePlaces.contains { $0.id == "fav-home" })
        #expect(sut.actionSucceeded)
    }

    @Test func sessionExpiredSetsFlagAndClearMessage() async {
        let repository = FailingFavoritePlaceRepository(error: FavoritePlaceError.sessionExpired)
        let sut = FavoritePlacesViewModel(
            getFavoritePlacesUseCase: GetFavoritePlacesUseCase(repository: repository),
            addFavoritePlaceUseCase: AddFavoritePlaceUseCase(repository: repository),
            updateFavoritePlaceUseCase: UpdateFavoritePlaceUseCase(repository: repository),
            removeFavoritePlaceUseCase: RemoveFavoritePlaceUseCase(repository: repository))

        sut.loadFavorites()
        await sut.activeTask?.value

        #expect(sut.isSessionExpired == true)
        #expect(sut.errorMessage == "Your session has expired. Please log in again.")
    }

    @Test func otherErrorsDoNotSetSessionExpiredFlag() async {
        let sut = makeSUT(behavior: .failure)

        sut.loadFavorites()
        await sut.activeTask?.value

        #expect(sut.isSessionExpired == false)
    }
}
