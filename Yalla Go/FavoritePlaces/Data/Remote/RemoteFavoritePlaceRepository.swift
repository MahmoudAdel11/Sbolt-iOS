
//
//  RemoteFavoritePlaceRepository.swift
//  Yalla Go
//

import Foundation

/// `FavoritePlaceRepository` backed by the Yalla Go REST API.
///
/// Stubs out as `NetworkError.serverError(statusCode: 501, ...)` until
/// each endpoint is wired and the DTO → domain mapping is filled in.
final class RemoteFavoritePlaceRepository: FavoritePlaceRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func getFavoritePlaces() async throws -> [FavoritePlace] {
        // TODO: let dtos: [FavoritePlaceDTO.FavoritePlaceResponse] = try await client.send(.getFavorites)
        // TODO: return dtos.map { $0.toDomain() }
        throw NetworkError.serverError(statusCode: 501, message: "Remote favorites not yet connected")
    }

    func addFavoritePlace(_ place: FavoritePlace) async throws -> [FavoritePlace] {
        // TODO: encode FavoritePlace → body, decode updated list
        throw NetworkError.serverError(statusCode: 501, message: "Remote favorites not yet connected")
    }

    func removeFavoritePlace(id: String) async throws -> [FavoritePlace] {
        // TODO: DELETE /favorites/{id}, decode updated list
        throw NetworkError.serverError(statusCode: 501, message: "Remote favorites not yet connected")
    }
}
