
//
//  RepositoryFactory.swift
//  Yalla Go
//

import Foundation

// MARK: - Protocol

/// Creates concrete repository implementations for every data feature.
///
/// Centralising construction here means swapping Mock ↔ Remote requires
/// changing only one property — `AppEnvironment.current` — with no changes
/// needed in ViewModels, use cases, or views.
protocol RepositoryFactory {
    func makeAuthenticationRepository() -> any AuthenticationRepository
    func makeProfileRepository() -> any ProfileRepository
    func makeTripRepository() -> any TripRepository
    func makeFavoritePlaceRepository() -> any FavoritePlaceRepository
    func makeSettingsRepository() -> any SettingsRepository
}

// MARK: - Mock factory  (development default)

/// Wires every feature to its in-memory mock implementation.
/// Used during development and in the automated test suite.
struct MockRepositoryFactory: RepositoryFactory {
    func makeAuthenticationRepository() -> any AuthenticationRepository { MockAuthenticationRepository() }
    func makeProfileRepository()        -> any ProfileRepository        { MockProfileRepository() }
    func makeTripRepository()           -> any TripRepository           { MockTripRepository() }
    func makeFavoritePlaceRepository()  -> any FavoritePlaceRepository  { MockFavoritePlaceRepository() }
    func makeSettingsRepository()       -> any SettingsRepository       { MockSettingsRepository() }
}

// MARK: - Remote factory  (production)

/// Wires every feature to its remote repository backed by `URLSessionAPIClient`.
///
/// Each remote repository stubs its methods as "Not yet connected" until the
/// backend endpoints are live and the DTO mapping is completed.
/// Settings are device-local and never have a remote implementation.
struct RemoteRepositoryFactory: RepositoryFactory {

    let client: any APIClient

    init(client: any APIClient = URLSessionAPIClient(baseURL: APIConfiguration.baseURL)) {
        self.client = client
    }

    func makeAuthenticationRepository() -> any AuthenticationRepository { RemoteAuthenticationRepository(client: client) }
    func makeProfileRepository()        -> any ProfileRepository        { RemoteProfileRepository(client: client) }
    func makeTripRepository()           -> any TripRepository           { RemoteTripRepository(client: client) }
    func makeFavoritePlaceRepository()  -> any FavoritePlaceRepository  { RemoteFavoritePlaceRepository(client: client) }
    func makeSettingsRepository()       -> any SettingsRepository       { MockSettingsRepository() }
}
