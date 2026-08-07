//
//  MockFavoritePlaceRepository.swift
//  Yalla Go
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

    func addFavoritePlace(_ place: FavoritePlace) async throws -> FavoritePlace {
        await simulateNetworkDelay()
        guard behavior == .success else { throw FavoritePlaceError.addFailed }
        places.removeAll { $0.id == place.id }
        places.append(place)
        return place
    }

    func updateFavoritePlace(id: String, _ place: FavoritePlace) async throws -> FavoritePlace {
        await simulateNetworkDelay()
        guard behavior == .success else { throw FavoritePlaceError.updateFailed }
        guard let index = places.firstIndex(where: { $0.id == id }) else {
            throw FavoritePlaceError.updateFailed
        }
        places[index] = place
        return place
    }

    func removeFavoritePlace(id: String) async throws {
        await simulateNetworkDelay()
        guard behavior == .success else { throw FavoritePlaceError.removeFailed }
        places.removeAll { $0.id == id }
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
                          createdAt: Date(timeIntervalSince1970: 1_719_000_000)),
            FavoritePlace(id: "fav-work",
                          title: "Work",
                          address: "Smart Village, Giza",
                          coordinate: Coordinate(latitude: 30.0713, longitude: 31.0170),
                          createdAt: Date(timeIntervalSince1970: 1_719_100_000)),
            FavoritePlace(id: "fav-gym",
                          title: "Gym",
                          address: "Maadi, Cairo",
                          coordinate: Coordinate(latitude: 29.9603, longitude: 31.2569),
                          createdAt: Date(timeIntervalSince1970: 1_719_200_000))
        ]
    }
}
