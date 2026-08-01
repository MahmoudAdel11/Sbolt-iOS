//
//  MockFavoritePlaceRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// In-memory `FavoritePlaceRepository` that simulates a backend while the app
/// has none. An `actor` guarantees safe access to the mutable store; `behavior`
/// and the injected list make success, failure, and empty scenarios deterministic.
actor MockFavoritePlaceRepository: FavoritePlaceRepository {

    enum Behavior {
        case success
        case failure
    }

    private var places: [FavoritePlace]
    private let behavior: Behavior
    private let artificialDelay: TimeInterval

    init(places: [FavoritePlace] = MockFavoritePlaceRepository.sampleFavorites(),
         behavior: Behavior = .success,
         artificialDelay: TimeInterval = 0.5) {
        self.places = places
        self.behavior = behavior
        self.artificialDelay = artificialDelay
    }

    func getFavoritePlaces() async throws -> [FavoritePlace] {
        await simulateNetworkDelay()
        guard behavior == .success else { throw FavoritePlaceError.loadFailed }
        return places
    }

    func addFavoritePlace(_ place: FavoritePlace) async throws -> [FavoritePlace] {
        await simulateNetworkDelay()
        guard behavior == .success else { throw FavoritePlaceError.addFailed }
        // Replace an existing entry with the same id, otherwise append.
        places.removeAll { $0.id == place.id }
        places.append(place)
        return places
    }

    func removeFavoritePlace(id: String) async throws -> [FavoritePlace] {
        await simulateNetworkDelay()
        guard behavior == .success else { throw FavoritePlaceError.removeFailed }
        places.removeAll { $0.id == id }
        return places
    }

    // MARK: - Helpers

    private func simulateNetworkDelay() async {
        guard artificialDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(artificialDelay * 1_000_000_000))
    }

    /// Deterministic saved places for previews and tests.
    static func sampleFavorites() -> [FavoritePlace] {
        [
            FavoritePlace(id: "fav-home",
                          title: "Home",
                          address: "12 El Nasr St, New Cairo",
                          coordinate: Coordinate(latitude: 30.0080, longitude: 31.4913),
                          icon: "house.fill",
                          createdAt: Date(timeIntervalSince1970: 1_719_000_000)),
            FavoritePlace(id: "fav-work",
                          title: "Work",
                          address: "Smart Village, Giza",
                          coordinate: Coordinate(latitude: 30.0713, longitude: 31.0170),
                          icon: "briefcase.fill",
                          createdAt: Date(timeIntervalSince1970: 1_719_100_000)),
            FavoritePlace(id: "fav-gym",
                          title: "Gym",
                          address: "Maadi, Cairo",
                          coordinate: Coordinate(latitude: 29.9603, longitude: 31.2569),
                          icon: "dumbbell.fill",
                          createdAt: Date(timeIntervalSince1970: 1_719_200_000))
        ]
    }
}
