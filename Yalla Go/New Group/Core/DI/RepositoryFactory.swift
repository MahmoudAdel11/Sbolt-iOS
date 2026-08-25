
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
    func makeDriverRepository() -> any DriverRepository
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
    func makeDriverRepository()         -> any DriverRepository         { MockDriverRepository() }
}

// MARK: - Remote factory  (production)

/// Wires every feature to its remote repository backed by `AuthenticatedAPIClient`.
///
/// Two `KeychainTokenStorage` instances are created once (access + refresh
/// slots — see `TokenAccount`); together they supply the token provider (for
/// automatic Bearer-header injection), the token refresher (for silent
/// renewal on 401 — see `AuthenticatedAPIClient`), and the auth repository
/// (for token persistence on login/register/logout). All other repositories
/// receive the authenticated client so their requests carry the token, and
/// transparently retry once after a silent refresh, automatically.
struct RemoteRepositoryFactory: RepositoryFactory {

    let client: any APIClient
    private let accessTokenStorage: any TokenStorage
    private let refreshTokenStorage: any TokenStorage

    init(accessTokenStorage: any TokenStorage = KeychainTokenStorage(account: TokenAccount.access),
         refreshTokenStorage: any TokenStorage = KeychainTokenStorage(account: TokenAccount.refresh),
         reachability: any NetworkReachabilityMonitoring = NWPathMonitorReachability()) {
        let provider = KeychainTokenProvider(storage: accessTokenStorage)
        let base = URLSessionAPIClient(baseURL: APIConfiguration.baseURL)
        let refresher = KeychainTokenRefresher(
            client: base,
            accessTokenStorage: accessTokenStorage,
            refreshTokenStorage: refreshTokenStorage
        )
        let authenticated = AuthenticatedAPIClient(
            client: base, tokenProvider: provider, tokenRefresher: refresher
        )
        self.client = RetryingAPIClient(inner: authenticated, reachability: reachability)
        self.accessTokenStorage = accessTokenStorage
        self.refreshTokenStorage = refreshTokenStorage
    }

    func makeAuthenticationRepository() -> any AuthenticationRepository {
        RemoteAuthenticationRepository(
            client: client,
            accessTokenStorage: accessTokenStorage,
            refreshTokenStorage: refreshTokenStorage
        )
    }
    func makeProfileRepository()        -> any ProfileRepository        { RemoteProfileRepository(client: client) }
    func makeTripRepository()           -> any TripRepository           { RemoteTripRepository(client: client) }
    func makeTripBookingRepository()    -> any TripBookingRepository    { RemoteTripBookingRepository(client: client) }
    func makeFavoritePlaceRepository()  -> any FavoritePlaceRepository  { RemoteFavoritePlaceRepository(client: client) }
    func makeSettingsRepository()       -> any SettingsRepository       { MockSettingsRepository() }
    func makeDriverRepository()         -> any DriverRepository         { RemoteDriverRepository(client: client) }
}
