//
//  RemoteAuthenticationRepository.swift
//  Yalla Go
//

import Foundation

/// `AuthenticationRepository` backed by the Yalla Go FastAPI backend.
///
/// Responsibilities:
/// - Encodes request bodies via `JSONEncoder.backend`.
/// - Sends typed endpoints via `APIClient`.
/// - Persists / clears the access token via `TokenStorage`.
/// - Maps `NetworkError` and HTTP status codes to `AuthenticationError`
///   so the Presentation layer never sees raw networking errors.
final class RemoteAuthenticationRepository: AuthenticationRepository {

    private let client: any APIClient
    private let tokenStorage: any TokenStorage

    init(client: any APIClient, tokenStorage: any TokenStorage) {
        self.client = client
        self.tokenStorage = tokenStorage
    }

    // MARK: - AuthenticationRepository

    func login(email: String, password: String) async throws -> User {
        do {
            let body = try JSONEncoder.backend.encode(
                AuthDTO.LoginRequest(email: email, password: password)
            )
            let loginDTO: AuthDTO.LoginResponse = try await client.send(
                Endpoint(path: "/auth/login", method: .post, body: body)
            )
            tokenStorage.save(loginDTO.accessToken)
            do {
                let userDTO: AuthDTO.UserResponse = try await client.send(
                    Endpoint(path: "/auth/me", method: .get)
                )
                return userDTO.toDomain()
            } catch {
                tokenStorage.delete()
                throw error
            }
        } catch {
            throw mapped(error)
        }
    }

    func register(_ details: RegistrationDetails) async throws -> User {
        do {
            let body = try JSONEncoder.backend.encode(
                AuthDTO.RegisterRequest(
                    fullName: details.username,
                    email: details.email,
                    phoneNumber: details.phoneNumber,
                    password: details.password
                )
            )
            let _: AuthDTO.UserResponse = try await client.send(
                Endpoint(path: "/auth/register", method: .post, body: body)
            )
        } catch {
            throw mapped(error)
        }
        return try await login(email: details.email, password: details.password)
    }

    func logout() async throws {
        defer { tokenStorage.delete() }
        do {
            let _: EmptyResponse = try await client.send(
                Endpoint(path: "/auth/logout", method: .post)
            )
        } catch NetworkError.noData {
            // 204 No Content — logout succeeded, body is empty
        } catch NetworkError.unauthorized {
            // Token was already invalid/expired — `defer` above already
            // cleared it, so the user is logged out either way.
        } catch {
            throw mapped(error)
        }
    }

    func currentUser() async -> User? {
        guard tokenStorage.retrieve() != nil else { return nil }
        do {
            let dto: AuthDTO.UserResponse = try await client.send(
                Endpoint(path: "/auth/me", method: .get)
            )
            return dto.toDomain()
        } catch NetworkError.unauthorized {
            tokenStorage.delete()   // Token expired or revoked — clear it
            return nil
        } catch {
            return nil              // Network/other transient failure — keep token
        }
    }

    func isAuthenticated() async -> Bool {
        tokenStorage.retrieve() != nil
    }

    // MARK: - Error mapping

    private func mapped(_ error: Error) -> AuthenticationError {
        if let authError = error as? AuthenticationError { return authError }
        switch error {
        case NetworkError.unauthorized:
            return .invalidCredentials
        case NetworkError.conflict:
            return .emailAlreadyExists
        case NetworkError.notFound:
            return .userNotFound
        case let NetworkError.serverError(statusCode, _) where statusCode == 422:
            return .validationFailed("Please check your details and try again.")
        case NetworkError.noInternet, NetworkError.timeout:
            return .networkUnavailable
        default:
            return .unknown
        }
    }
}
