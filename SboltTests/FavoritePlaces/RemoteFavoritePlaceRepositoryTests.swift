//
//  RemoteFavoritePlaceRepositoryTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

private final class StubAPIClient: APIClient {
    enum StubResult {
        case success(Data)
        case failure(Error)
    }

    var result: StubResult = .failure(NetworkError.unknown("unset"))
    private(set) var capturedEndpoint: Endpoint?

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        capturedEndpoint = endpoint
        switch result {
        case .success(let data):
            return try JSONDecoder.backend.decode(T.self, from: data)
        case .failure(let error):
            throw error
        }
    }
}

private func placeJSON(id: String = "fav-1", label: String = "Home") -> Data {
    let json = """
    {
        "id": "\(id)", "label": "\(label)", "address": "12 El Nasr St, New Cairo",
        "latitude": 30.0080, "longitude": 31.4913,
        "created_at": "2026-01-01T00:00:00.000000Z"
    }
    """
    return Data(json.utf8)
}

private func makePlace(id: String = "fav-1", title: String = "Home") -> FavoritePlace {
    FavoritePlace(id: id, title: title, address: "12 El Nasr St, New Cairo",
                 coordinate: Coordinate(latitude: 30.0080, longitude: 31.4913),
                 createdAt: Date(timeIntervalSince1970: 0))
}

struct RemoteFavoritePlaceRepositoryTests {

    @Test func getFavoritePlacesSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(Data("[\(String(data: placeJSON(), encoding: .utf8)!)]".utf8))
        let sut = RemoteFavoritePlaceRepository(client: client)

        let places = try await sut.getFavoritePlaces()

        #expect(places.count == 1)
        #expect(places.first?.title == "Home")
        #expect(places.first?.icon == "house.fill")
        #expect(client.capturedEndpoint?.path == "/favorite-places")
        #expect(client.capturedEndpoint?.method == .get)
    }

    @Test func addFavoritePlaceSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(placeJSON())
        let sut = RemoteFavoritePlaceRepository(client: client)

        let place = try await sut.addFavoritePlace(makePlace())

        #expect(place.title == "Home")
        #expect(client.capturedEndpoint?.path == "/favorite-places")
        #expect(client.capturedEndpoint?.method == .post)

        let body = try #require(client.capturedEndpoint?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["label"] as? String == "Home")
    }

    @Test func addFavoritePlaceMapsConflictToDuplicateLabel() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: nil))
        let sut = RemoteFavoritePlaceRepository(client: client)

        await #expect(throws: FavoritePlaceError.duplicateLabel) {
            _ = try await sut.addFavoritePlace(makePlace())
        }
    }

    @Test func updateFavoritePlaceSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(placeJSON(label: "Updated Home"))
        let sut = RemoteFavoritePlaceRepository(client: client)

        let place = try await sut.updateFavoritePlace(id: "fav-1", makePlace(title: "Updated Home"))

        #expect(place.title == "Updated Home")
        #expect(client.capturedEndpoint?.path == "/favorite-places/fav-1")
        #expect(client.capturedEndpoint?.method == .patch)
    }

    @Test func updateFavoritePlaceMapsNotFound() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.notFound)
        let sut = RemoteFavoritePlaceRepository(client: client)

        await #expect(throws: FavoritePlaceError.updateFailed) {
            _ = try await sut.updateFavoritePlace(id: "fav-1", makePlace())
        }
    }

    @Test func removeFavoritePlaceSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.noData) // 204 → treated as success
        let sut = RemoteFavoritePlaceRepository(client: client)

        try await sut.removeFavoritePlace(id: "fav-1")

        #expect(client.capturedEndpoint?.path == "/favorite-places/fav-1")
        #expect(client.capturedEndpoint?.method == .delete)
    }

    @Test func removeFavoritePlaceMapsForbidden() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.forbidden)
        let sut = RemoteFavoritePlaceRepository(client: client)

        await #expect(throws: FavoritePlaceError.removeFailed) {
            try await sut.removeFavoritePlace(id: "fav-1")
        }
    }

    @Test func unauthorizedMapsToSessionExpiredOnAllCalls() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let sut = RemoteFavoritePlaceRepository(client: client)

        await #expect(throws: FavoritePlaceError.sessionExpired) {
            _ = try await sut.getFavoritePlaces()
        }
        await #expect(throws: FavoritePlaceError.sessionExpired) {
            _ = try await sut.addFavoritePlace(makePlace())
        }
        await #expect(throws: FavoritePlaceError.sessionExpired) {
            _ = try await sut.updateFavoritePlace(id: "fav-1", makePlace())
        }
        await #expect(throws: FavoritePlaceError.sessionExpired) {
            try await sut.removeFavoritePlace(id: "fav-1")
        }
    }

    @Test func networkFailureMapsToNetworkUnavailable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.noInternet)
        let sut = RemoteFavoritePlaceRepository(client: client)

        await #expect(throws: FavoritePlaceError.networkUnavailable) {
            _ = try await sut.getFavoritePlaces()
        }
    }
}
