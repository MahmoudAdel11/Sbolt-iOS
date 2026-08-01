//
//  FavoritePlaceUseCaseTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

struct FavoritePlaceUseCaseTests {

    private func makePlace(id: String = "fav-new") -> FavoritePlace {
        FavoritePlace(id: id,
                      title: "University",
                      address: "GUC, New Cairo",
                      coordinate: Coordinate(latitude: 29.9866, longitude: 31.4426),
                      icon: "graduationcap.fill",
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

    @Test func addReturnsUpdatedList() async throws {
        let repository = MockFavoritePlaceRepository(artificialDelay: 0)
        let sut = AddFavoritePlaceUseCase(repository: repository)
        let places = try await sut.execute(makePlace())
        #expect(places.contains { $0.id == "fav-new" })
    }

    @Test func addPropagatesFailure() async {
        let repository = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        let sut = AddFavoritePlaceUseCase(repository: repository)
        await #expect(throws: FavoritePlaceError.addFailed) {
            _ = try await sut.execute(makePlace())
        }
    }

    // MARK: - Remove

    @Test func removeReturnsUpdatedList() async throws {
        let repository = MockFavoritePlaceRepository(artificialDelay: 0)
        let sut = RemoveFavoritePlaceUseCase(repository: repository)
        let places = try await sut.execute(id: "fav-home")
        #expect(!places.contains { $0.id == "fav-home" })
    }

    @Test func removePropagatesFailure() async {
        let repository = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        let sut = RemoveFavoritePlaceUseCase(repository: repository)
        await #expect(throws: FavoritePlaceError.removeFailed) {
            _ = try await sut.execute(id: "fav-home")
        }
    }
}
