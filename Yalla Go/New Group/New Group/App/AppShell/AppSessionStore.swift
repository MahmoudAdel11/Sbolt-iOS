//
//  AppSessionStore.swift
//  Yalla Go
//

import Foundation

/// Which tab set the app is currently showing. Independent of `currentUser`'s
/// driver capability (`User.driverProfile`) — a user can have driver capability
/// and still be viewing Customer mode.
enum AppMode: Equatable {
    case customer
    case driver
}

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
/// 6. `currentMode` decides which tab set `RootView`/`MainTabView` shows
///    (Customer vs Driver). It intentionally does NOT persist across
///    launches — every cold start (including post-login) begins in
///    `.customer`, and `switchMode(to:)` is the only way to change it,
///    gated by `currentUser?.driverProfile != nil` so a rider-only account
///    can never end up in Driver mode.
@MainActor
final class AppSessionStore: ObservableObject {

    @Published private(set) var currentUser: User?
    @Published private(set) var currentMode: AppMode = .customer

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
        currentMode = .customer
    }

    /// Transitions the app into the unauthenticated state and clears the
    /// persisted Keychain token, so a stale/expired token can never be
    /// reused on the next launch.
    func signOut() {
        KeychainTokenStorage(account: TokenAccount.access).delete()
        KeychainTokenStorage(account: TokenAccount.refresh).delete()
        currentUser = nil
        currentMode = .customer
    }

    /// Switches the active tab set. A no-op if the target is `.driver` and
    /// the current user has no driver profile — callers (Settings) should
    /// also avoid presenting the control in that case, but this is enforced
    /// here too so nothing else can bypass it.
    func switchMode(to mode: AppMode) {
        guard mode == .customer || currentUser?.driverProfile != nil else { return }
        currentMode = mode
    }
}
