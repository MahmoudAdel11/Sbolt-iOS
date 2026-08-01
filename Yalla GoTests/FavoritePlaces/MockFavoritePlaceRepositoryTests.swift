//
//  MockFavoritePlaceRepositoryTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

struct MockFavoritePlaceRepositoryTests {

    private func makePlace(id: String = "fav-new") -> FavoritePlace {
        FavoritePlace(id: id,
                      title: "University",
                      address: "GUC, New Cairo",
                      coordinate: Coordinate(latitude: 29.9866, longitude: 31.4426),
                      icon: "graduationcap.fill",
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

    @Test func addAppendsAndReturnsUpdatedList() async throws {
        let sut = MockFavoritePlaceRepository(artificialDelay: 0)
        let updated = try await sut.addFavoritePlace(makePlace())
        #expect(updated.count == 4)
        #expect(updated.contains { $0.id == "fav-new" })
    }

    @Test func addFails() async {
        let sut = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: FavoritePlaceError.addFailed) {
            _ = try await sut.addFavoritePlace(makePlace())
        }
    }

    @Test func removeDeletesAndReturnsUpdatedList() async throws {
        let sut = MockFavoritePlaceRepository(artificialDelay: 0)
        let updated = try await sut.removeFavoritePlace(id: "fav-home")
        #expect(updated.count == 2)
        #expect(!updated.contains { $0.id == "fav-home" })
    }

    @Test func removeFails() async {
        let sut = MockFavoritePlaceRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: FavoritePlaceError.removeFailed) {
            _ = try await sut.removeFavoritePlace(id: "fav-home")
        }
    }
}
