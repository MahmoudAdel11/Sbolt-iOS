//
//  AppSessionStore.swift
//  Yalla Go
//

import Foundation

/// Single source of truth for the authenticated session across the entire app.
///
/// Lifecycle:
/// 1. App launches → `Yalla_GoApp` calls `bootstrap()` via `.task`.
/// 2. `bootstrap()` runs `SessionBootstrapUseCase`:
///    - If a valid Keychain token exists and `/auth/me` succeeds → `currentUser` is set.
///    - Otherwise (no token, expired token, or network failure) → `currentUser` stays nil.
/// 3. Views observe `isAuthenticated` to decide which root to show.
/// 4. `signIn(user:)` is called by Login/Register views on success.
/// 5. `signOut()` is called by the profile/settings flow on logout, and by
///    any feature ViewModel that detects a `.sessionExpired` domain error
///    (expired/invalid token mid-session) — it clears the Keychain token
///    itself, so callers never need a separate `LogoutUseCase` call just to
///    end the session locally.
@MainActor
final class AppSessionStore: ObservableObject {

    @Published private(set) var currentUser: User?

    var isAuthenticated: Bool { currentUser != nil }

    private let bootstrapUseCase: SessionBootstrapUseCase

    init() {
        let factory = AppEnvironment.current.repositoryFactory
        self.bootstrapUseCase = SessionBootstrapUseCase(
            repository: factory.makeAuthenticationRepository()
        )
    }

    /// Restores a previous session from Keychain. Call once on app launch.
    func bootstrap() async {
        currentUser = await bootstrapUseCase.execute()
    }

    /// Transitions the app into the authenticated state.
    func signIn(user: User) {
        currentUser = user
    }

    /// Transitions the app into the unauthenticated state and clears the
    /// persisted Keychain token, so a stale/expired token can never be
    /// reused on the next launch.
    func signOut() {
        KeychainTokenStorage().delete()
        currentUser = nil
    }
}
