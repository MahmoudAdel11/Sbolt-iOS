
//
//  RemoteAuthenticationRepository.swift
//  Yalla Go
//

import Foundation

/// `AuthenticationRepository` backed by the Yalla Go REST API.
///
/// Each method stubs out as `NetworkError.serverError(statusCode: 501, ...)`
/// until the corresponding endpoint is wired and the DTO mapping is filled in.
/// Replace the `throw` line with the real `client.send(...)` call per endpoint.
final class RemoteAuthenticationRepository: AuthenticationRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> User {
        // TODO: let dto: AuthDTO.LoginResponse = try await client.send(.login(email: email, password: password))
        // TODO: return dto.toDomain()
        throw NetworkError.serverError(statusCode: 501, message: "Remote auth not yet connected")
    }

    func register(_ details: RegistrationDetails) async throws -> User {
        // TODO: let dto: AuthDTO.LoginResponse = try await client.send(.register(details))
        // TODO: return dto.toDomain()
        throw NetworkError.serverError(statusCode: 501, message: "Remote auth not yet connected")
    }

    func logout() async throws {
        // TODO: try await client.send(.logout) as Void-equivalent
        throw NetworkError.serverError(statusCode: 501, message: "Remote auth not yet connected")
    }

    func currentUser() async -> User? {
        // TODO: derive from a persisted token / session store
        return nil
    }

    func isAuthenticated() async -> Bool {
        // TODO: check stored token validity
        return false
    }
}
