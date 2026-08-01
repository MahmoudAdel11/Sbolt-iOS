
//
//  RemoteProfileRepository.swift
//  Yalla Go
//

import Foundation

/// `ProfileRepository` backed by the Yalla Go REST API.
///
/// Stubs out as `NetworkError.serverError(statusCode: 501, ...)` until
/// the endpoint is wired and the DTO → domain mapping is filled in.
final class RemoteProfileRepository: ProfileRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func getProfile() async throws -> User {
        // TODO: let dto: ProfileDTO.ProfileResponse = try await client.send(.getProfile)
        // TODO: return dto.toDomain()
        throw NetworkError.serverError(statusCode: 501, message: "Remote profile not yet connected")
    }

    func updateProfile(_ update: ProfileUpdate) async throws -> User {
        // TODO: encode ProfileUpdate → body, let dto: ProfileDTO.ProfileResponse = try await client.send(.updateProfile(body))
        // TODO: return dto.toDomain()
        throw NetworkError.serverError(statusCode: 501, message: "Remote profile not yet connected")
    }
}
