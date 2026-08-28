//
//  MockFavoritePlaceRepositoryTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

struct MockFavoritePlaceRepositoryTests {

    private func makePlace(id: String = "fav-new", title: String = "University") -> FavoritePlace {
        FavoritePlace(id: id,
                      title: title,
                      address: "GUC, New Cairo",
                      coordinate: Coordinate(latitude: 29.9866, longitude: 31.4426),
                      createdAt: Date(timeIntervalSince1970: 1_719_300_000))
    }

    @Test func loadReturnsSampleFavoritesOnSuccess() async throws {
        let sut = MockFavoritePlaceRepository(artificialDelay: 0)
        let places = try await sut.getFavoritePlaces()
        #expect(places.count == 3)
        #expect(places.first?.id == "fav-home")
    }

    @Test func loadReturnsEmptyWhenNoFavorites() async throws {
        let sut = MockFavoritePlaceRepository(places: [], artificialDelay: 0)
        let places = try await sut.getFavoritePlaces()
        #expect(places.isEmpty)
    }

    @Test func loadFails() async {
        let sut = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: FavoritePlaceError.loadFailed) {
            _ = try await sut.getFavoritePlaces()
        }
    }

    @Test func addReturnsCreatedPlaceAndAppendsToStore() async throws {
        let sut = MockFavoritePlaceRepository(artificialDelay: 0)
        let created = try await sut.addFavoritePlace(makePlace())
        #expect(created.id == "fav-new")

        let all = try await sut.getFavoritePlaces()
        #expect(all.count == 4)
    }

    @Test func addFails() async {
        let sut = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: FavoritePlaceError.addFailed) {
            _ = try await sut.addFavoritePlace(makePlace())
        }
    }

    @Test func updateReturnsUpdatedPlaceAndReplacesInStore() async throws {
        let sut = MockFavoritePlaceRepository(artificialDelay: 0)
        let updated = try await sut.updateFavoritePlace(id: "fav-home", makePlace(id: "fav-home", title: "New Home"))
        #expect(updated.title == "New Home")

        let all = try await sut.getFavoritePlaces()
        #expect(all.count == 3) // replaced, not appended
        #expect(all.first { $0.id == "fav-home" }?.title == "New Home")
    }

    @Test func updateFailsForUnknownId() async {
        let sut = MockFavoritePlaceRepository(artificialDelay: 0)
        await #expect(throws: FavoritePlaceError.updateFailed) {
            _ = try await sut.updateFavoritePlace(id: "missing", makePlace())
        }
    }

    @Test func updateFails() async {
        let sut = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: FavoritePlaceError.updateFailed) {
            _ = try await sut.updateFavoritePlace(id: "fav-home", makePlace())
        }
    }

    @Test func removeDeletesFromStore() async throws {
        let sut = MockFavoritePlaceRepository(artificialDelay: 0)
        try await sut.removeFavoritePlace(id: "fav-home")

        let all = try await sut.getFavoritePlaces()
        #expect(all.count == 2)
        #expect(!all.contains { $0.id == "fav-home" })
    }

    @Test func removeFails() async {
        let sut = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: FavoritePlaceError.removeFailed) {
            try await sut.removeFavoritePlace(id: "fav-home")
        }
    }
}
