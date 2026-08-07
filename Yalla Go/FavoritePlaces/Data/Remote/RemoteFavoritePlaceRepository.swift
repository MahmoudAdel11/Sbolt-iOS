
//
//  RemoteFavoritePlaceRepository.swift
//  Yalla Go
//

import Foundation

/// `FavoritePlaceRepository` backed by the Yalla Go REST API.
final class RemoteFavoritePlaceRepository: FavoritePlaceRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func getFavoritePlaces() async throws -> [FavoritePlace] {
        do {
            let dtos: [FavoritePlaceDTO.FavoritePlaceResponse] = try await client.send(
                Endpoint(path: "/favorite-places", method: .get)
            )
            return dtos.map { $0.toDomain() }
        } catch {
            throw mapped(error, notFound: .loadFailed, conflict: .loadFailed)
        }
    }

    func addFavoritePlace(_ place: FavoritePlace) async throws -> FavoritePlace {
        do {
            let body = try JSONEncoder.backend.encode(FavoritePlaceDTO.FavoritePlaceCreateRequest(place))
            let dto: FavoritePlaceDTO.FavoritePlaceResponse = try await client.send(
                Endpoint(path: "/favorite-places", method: .post, body: body)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error, notFound: .addFailed, conflict: .duplicateLabel)
        }
    }

    func updateFavoritePlace(id: String, _ place: FavoritePlace) async throws -> FavoritePlace {
        do {
            let body = try JSONEncoder.backend.encode(FavoritePlaceDTO.FavoritePlaceUpdateRequest(place))
            let dto: FavoritePlaceDTO.FavoritePlaceResponse = try await client.send(
                Endpoint(path: "/favorite-places/\(id)", method: .patch, body: body)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error, notFound: .updateFailed, conflict: .duplicateLabel)
        }
    }

    func removeFavoritePlace(id: String) async throws {
        do {
            let _: EmptyResponse = try await client.send(
                Endpoint(path: "/favorite-places/\(id)", method: .delete)
            )
        } catch NetworkError.noData {
            // 204 No Content — delete succeeded, body is empty
        } catch {
            throw mapped(error, notFound: .removeFailed, conflict: .removeFailed)
        }
    }

    // MARK: - Error mapping

    private func mapped(_ error: Error, notFound: FavoritePlaceError, conflict: FavoritePlaceError) -> FavoritePlaceError {
        if let placeError = error as? FavoritePlaceError { return placeError }
        switch error {
        case NetworkError.unauthorized:
            return .sessionExpired
        case NetworkError.forbidden:
            return notFound
        case NetworkError.notFound:
            return notFound
        case NetworkError.conflict:
            return conflict
        case NetworkError.noInternet, NetworkError.timeout:
            return .networkUnavailable
        default:
            return .unknown
        }
    }
}
