
//
//  RemoteProfileRepository.swift
//  Yalla Go
//

import Foundation

/// `ProfileRepository` backed by the Yalla Go REST API.
final class RemoteProfileRepository: ProfileRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func getProfile() async throws -> User {
        do {
            let dto: ProfileDTO.ProfileResponse = try await client.send(
                Endpoint(path: "/auth/me", method: .get)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error)
        }
    }

    func updateProfile(_ update: ProfileUpdate) async throws -> User {
        do {
            let body = try JSONEncoder.backend.encode(ProfileDTO.ProfileUpdateRequest(update))
            let dto: ProfileDTO.ProfileResponse = try await client.send(
                Endpoint(path: "/users/me", method: .patch, body: body)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error)
        }
    }

    // MARK: - Error mapping

    private func mapped(_ error: Error) -> ProfileError {
        if let profileError = error as? ProfileError { return profileError }
        switch error {
        case NetworkError.unauthorized:
            return .sessionExpired
        case NetworkError.forbidden, NetworkError.notFound:
            return .profileUnavailable
        case NetworkError.noInternet, NetworkError.timeout:
            return .networkUnavailable
        case NetworkError.conflict:
            return .updateFailed
        case let NetworkError.serverError(statusCode, _) where (400...499).contains(statusCode):
            return .updateFailed
        default:
            return .unknown
        }
    }
}
