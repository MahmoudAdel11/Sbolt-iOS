
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
    func makeTripBookingRepository() -> any TripBookingRepository
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
    func makeTripBookingRepository()    -> any TripBookingRepository    { MockTripBookingRepository() }
    func makeFavoritePlaceRepository()  -> any FavoritePlaceRepository  { MockFavoritePlaceRepository() }
    func makeSettingsRepository()       -> any SettingsRepository       { MockSettingsRepository() }
}

// MARK: - Remote factory  (production)

/// Wires every feature to its remote repository backed by `AuthenticatedAPIClient`.
///
/// `KeychainTokenStorage` is created once; it supplies both the token provider
/// (for automatic Bearer-header injection) and the auth repository (for
/// token persistence on login/logout). All other repositories receive the
/// authenticated client so their requests carry the token automatically.
struct RemoteRepositoryFactory: RepositoryFactory {

    let client: any APIClient
    private let tokenStorage: any TokenStorage

    init(tokenStorage: any TokenStorage = KeychainTokenStorage(),
         reachability: any NetworkReachabilityMonitoring = NWPathMonitorReachability()) {
        let provider = KeychainTokenProvider(storage: tokenStorage)
        let base = URLSessionAPIClient(baseURL: APIConfiguration.baseURL)
        let authenticated = AuthenticatedAPIClient(client: base, tokenProvider: provider)
        self.client = RetryingAPIClient(inner: authenticated, reachability: reachability)
        self.tokenStorage = tokenStorage
    }

    func makeAuthenticationRepository() -> any AuthenticationRepository {
        RemoteAuthenticationRepository(client: client, tokenStorage: tokenStorage)
    }
    func makeProfileRepository()        -> any ProfileRepository        { RemoteProfileRepository(client: client) }
    func makeTripRepository()           -> any TripRepository           { RemoteTripRepository(client: client) }
    func makeTripBookingRepository()    -> any TripBookingRepository    { RemoteTripBookingRepository(client: client) }
    func makeFavoritePlaceRepository()  -> any FavoritePlaceRepository  { RemoteFavoritePlaceRepository(client: client) }
    func makeSettingsRepository()       -> any SettingsRepository       { MockSettingsRepository() }
}
