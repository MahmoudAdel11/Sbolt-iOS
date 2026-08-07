//
//  FavoritePlaceUseCaseTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

struct FavoritePlaceUseCaseTests {

    private func makePlace(id: String = "fav-new", title: String = "University") -> FavoritePlace {
        FavoritePlace(id: id,
                      title: title,
                      address: "GUC, New Cairo",
                      coordinate: Coordinate(latitude: 29.9866, longitude: 31.4426),
                      createdAt: Date(timeIntervalSince1970: 1_719_300_000))
    }

    // MARK: - Get

    @Test func getReturnsFavorites() async throws {
        let repository = MockFavoritePlaceRepository(artificialDelay: 0)
        let sut = GetFavoritePlacesUseCase(repository: repository)
        let places = try await sut.execute()
        #expect(places.count == 3)
    }

    @Test func getPropagatesFailure() async {
        let repository = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        let sut = GetFavoritePlacesUseCase(repository: repository)
        await #expect(throws: FavoritePlaceError.loadFailed) {
            _ = try await sut.execute()
        }
    }

    // MARK: - Add

    @Test func addReturnsCreatedPlace() async throws {
        let repository = MockFavoritePlaceRepository(artificialDelay: 0)
        let sut = AddFavoritePlaceUseCase(repository: repository)
        let place = try await sut.execute(makePlace())
        #expect(place.id == "fav-new")
    }

    @Test func addPropagatesFailure() async {
        let repository = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        let sut = AddFavoritePlaceUseCase(repository: repository)
        await #expect(throws: FavoritePlaceError.addFailed) {
            _ = try await sut.execute(makePlace())
        }
    }

    // MARK: - Update

    @Test func updateReturnsUpdatedPlace() async throws {
        let repository = MockFavoritePlaceRepository(artificialDelay: 0)
        let sut = UpdateFavoritePlaceUseCase(repository: repository)
        let place = try await sut.execute(id: "fav-home", makePlace(id: "fav-home", title: "New Home"))
        #expect(place.title == "New Home")
    }

    @Test func updatePropagatesFailure() async {
        let repository = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        let sut = UpdateFavoritePlaceUseCase(repository: repository)
        await #expect(throws: FavoritePlaceError.updateFailed) {
            _ = try await sut.execute(id: "fav-home", makePlace())
        }
    }

    // MARK: - Remove

    @Test func removeCompletesOnSuccess() async throws {
        let repository = MockFavoritePlaceRepository(artificialDelay: 0)
        let sut = RemoveFavoritePlaceUseCase(repository: repository)
        try await sut.execute(id: "fav-home")

        let remaining = try await repository.getFavoritePlaces()
        #expect(!remaining.contains { $0.id == "fav-home" })
    }

    @Test func removePropagatesFailure() async {
        let repository = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        let sut = RemoveFavoritePlaceUseCase(repository: repository)
        await #expect(throws: FavoritePlaceError.removeFailed) {
            try await sut.execute(id: "fav-home")
        }
    }
}
